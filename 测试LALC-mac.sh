#!/bin/bash
# LALC macOS 功能验证脚本

echo "========================================"
echo "LALC macOS 功能验证"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

FAILED=0

# 查找 Python（与启动脚本相同逻辑）
find_python() {
    if command -v conda &> /dev/null && [ -n "${CONDA_PREFIX:-}" ]; then
        if [ -x "$CONDA_PREFIX/bin/python" ]; then
            echo "$CONDA_PREFIX/bin/python"
            return 0
        fi
    fi
    if command -v python3 &> /dev/null; then
        echo "python3"
        return 0
    fi
    if command -v python &> /dev/null; then
        echo "python"
        return 0
    fi
    return 1
}

PYTHON_BIN=$(find_python)

# 测试1: Python 环境
echo "✓ 测试 1: Python 环境检测"
if [ -n "$PYTHON_BIN" ]; then
    PYTHON_VERSION=$("$PYTHON_BIN" --version 2>&1)
    echo "  找到: $PYTHON_VERSION"
    echo "  路径: $PYTHON_BIN"
else
    echo "  ❌ 失败: 未找到 Python"
    FAILED=1
fi
echo ""

# 测试2: 依赖检查
echo "✓ 测试 2: 检查依赖包"
cd lalc_backend
DEPS=("pynput" "PIL" "websockets" "onnxruntime" "cv2")
for dep in "${DEPS[@]}"; do
    if "$PYTHON_BIN" -c "import $dep" 2>/dev/null; then
        echo "  ✓ $dep"
    else
        echo "  ❌ $dep (未安装)"
        FAILED=1
    fi
done
echo ""

# 测试3: 窗口检测工具
echo "✓ 测试 3: 窗口检测工具"
if "$PYTHON_BIN" -m utils.window_detector --list > /dev/null 2>&1; then
    WINDOW_COUNT=$("$PYTHON_BIN" -m utils.window_detector --list 2>&1 | grep "找到.*个窗口" | grep -o '[0-9]*')
    echo "  找到 $WINDOW_COUNT 个窗口"
else
    echo "  ❌ 窗口检测失败"
    FAILED=1
fi
echo ""

# 测试4: 编译测试
echo "✓ 测试 4: Python 语法检查"
FILES=("input/mac_adapter.py" "input/input_handler.py" "utils/window_detector.py" "main.py")
for file in "${FILES[@]}"; do
    if "$PYTHON_BIN" -m py_compile "$file" 2>/dev/null; then
        echo "  ✓ $file"
    else
        echo "  ❌ $file"
        FAILED=1
    fi
done
echo ""

# 测试5: 加密降级
echo "✓ 测试 5: 加密降级测试"
cd "$SCRIPT_DIR/lalc_backend"
RESULT=$("$PYTHON_BIN" -c "
from utils.encrypt_decrypt import encrypt_cdk, decrypt_cdk
encrypted = encrypt_cdk('test123')
decrypted = decrypt_cdk(encrypted)
print('OK' if decrypted == 'test123' else 'FAIL')
print(f'(格式: {encrypted[:10]}...)')
" 2>&1)

if echo "$RESULT" | grep -q "OK"; then
    echo "  ✓ 加密/解密正常"
    echo "  $(echo "$RESULT" | tail -1)"
else
    echo "  ❌ 加密/解密失败"
    FAILED=1
fi
echo ""

# 测试6: 启动脚本
echo "✓ 测试 6: 启动脚本语法"
cd "$SCRIPT_DIR"
if bash -n 启动LALC-mac.sh && bash -n 安装LALC-mac.sh; then
    echo "  ✓ 脚本语法正确"
else
    echo "  ❌ 脚本语法错误"
    FAILED=1
fi
echo ""

# 总结
echo "========================================"
if [ $FAILED -eq 0 ]; then
    echo "✅ 所有测试通过！"
    echo ""
    echo "LALC 已准备就绪，可以启动："
    echo "  ./启动LALC-mac.sh"
else
    echo "❌ 部分测试失败"
    echo ""
    echo "请检查上面的错误信息，或运行："
    echo "  ./安装LALC-mac.sh"
fi
echo "========================================"

exit $FAILED
