#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/lalc_backend"

# Smart Python detection
find_python() {
    # Try conda python if available
    if command -v conda &> /dev/null && [ -n "${CONDA_PREFIX:-}" ]; then
        if [ -x "$CONDA_PREFIX/bin/python" ]; then
            echo "$CONDA_PREFIX/bin/python"
            return 0
        fi
    fi
    
    # Try python3 in PATH
    if command -v python3 &> /dev/null; then
        echo "python3"
        return 0
    fi
    
    # Try python in PATH
    if command -v python &> /dev/null; then
        echo "python"
        return 0
    fi
    
    echo "错误: 未找到 Python。请先安装 Python 3.12+ 或激活 conda 环境。" >&2
    exit 1
}

PYTHON_BIN=$(find_python)

# Verify Python version
PYTHON_VERSION=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "使用 Python: $PYTHON_BIN (版本 $PYTHON_VERSION)"

export LALC_WINDOW_LEFT="${LALC_WINDOW_LEFT:-0}"
export LALC_WINDOW_TOP="${LALC_WINDOW_TOP:-0}"
export LALC_WINDOW_WIDTH="${LALC_WINDOW_WIDTH:-1302}"
export LALC_WINDOW_HEIGHT="${LALC_WINDOW_HEIGHT:-776}"

echo "========================================"
echo "LALC macOS 启动器"
echo "========================================"
echo "窗口区域: ${LALC_WINDOW_LEFT},${LALC_WINDOW_TOP},${LALC_WINDOW_WIDTH},${LALC_WINDOW_HEIGHT}"
echo ""
echo "注意事项："
echo "1. 请先在 系统设置→隐私与安全性 中授予权限："
echo "   - 屏幕录制权限（用于截图）"
echo "   - 辅助功能权限（用于鼠标/键盘控制）"
echo "2. 首次运行系统会弹窗请求权限，授予后需重启程序"
echo ""
echo "启动后端服务器..."
echo ""

cd "$BACKEND_DIR"
exec "$PYTHON_BIN" main.py
