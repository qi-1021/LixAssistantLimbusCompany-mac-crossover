#!/bin/bash
# LALC macOS 一键安装脚本
set -e

echo "========================================"
echo "LALC macOS 安装程序"
echo "========================================"
echo ""

# 检测 Python
echo "🔍 检查 Python 环境..."
if command -v python3 &> /dev/null; then
    PYTHON_BIN="python3"
    PYTHON_VERSION=$($PYTHON_BIN --version 2>&1 | cut -d' ' -f2)
    echo "✓ 找到 Python $PYTHON_VERSION"
    
    # 检查版本
    MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
    
    if [ "$MAJOR" -lt 3 ] || { [ "$MAJOR" -eq 3 ] && [ "$MINOR" -lt 10 ]; }; then
        echo "❌ Python 版本过低，需要 3.10+，当前为 $PYTHON_VERSION"
        echo ""
        echo "请安装新版 Python："
        echo "  brew install python@3.12"
        echo "或"
        echo "  conda install python=3.12"
        exit 1
    fi
else
    echo "❌ 未找到 Python"
    echo ""
    echo "请先安装 Python 3.10+："
    echo "  brew install python@3.12"
    echo "或使用 conda:"
    echo "  conda create -n lalc python=3.12"
    echo "  conda activate lalc"
    exit 1
fi

echo ""
echo "📦 安装依赖包..."
cd "$(dirname "$0")/lalc_backend"

if $PYTHON_BIN -m pip install -e . ; then
    echo "✓ 依赖安装成功"
else
    echo "❌ 依赖安装失败"
    echo ""
    echo "请尝试手动安装："
    echo "  cd lalc_backend"
    echo "  pip install -e ."
    exit 1
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "下一步："
echo "1. 授予系统权限："
echo "   系统设置 → 隐私与安全性 → 屏幕录制 (勾选终端)"
echo "   系统设置 → 隐私与安全性 → 辅助功能 (勾选终端)"
echo ""
echo "2. 启动 LALC："
echo "   ./启动LALC-mac.sh"
echo ""
echo "3. 查看使用文档："
echo "   cat README_macOS.md"
echo ""
