#!/bin/bash
# LALC macOS 离线安装脚本（使用本地依赖包）

set -e

echo "========================================"
echo "LALC macOS 离线安装程序"
echo "========================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

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
echo "📦 使用本地依赖包安装..."
cd "$SCRIPT_DIR/lalc_backend"

# 检查依赖包目录
if [ -d "deps_macos" ] && [ "$(ls -A deps_macos)" ]; then
    echo "✓ 找到本地依赖包 ($(ls deps_macos | wc -l | tr -d ' ') 个文件)"
    
    # 从本地安装
    if $PYTHON_BIN -m pip install --no-index --find-links=deps_macos -r requirements-macos.txt ; then
        echo "✓ 依赖安装成功（离线模式）"
    else
        echo "❌ 离线安装失败，尝试在线安装..."
        if $PYTHON_BIN -m pip install -e . ; then
            echo "✓ 依赖安装成功（在线模式）"
        else
            echo "❌ 依赖安装失败"
            exit 1
        fi
    fi
else
    echo "⚠️  未找到本地依赖包，使用在线安装..."
    if $PYTHON_BIN -m pip install -e . ; then
        echo "✓ 依赖安装成功（在线模式）"
    else
        echo "❌ 依赖安装失败"
        exit 1
    fi
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
