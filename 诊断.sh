#!/usr/bin/env bash
#
# LALC 诊断工具
# 帮助用户检查问题
#

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

echo "════════════════════════════════════════════════"
echo "           LALC 诊断工具"
echo "════════════════════════════════════════════════"
echo ""

# 1. Python 检查
echo "1️⃣ Python 检查"
echo "─────────────────────────────────────────────────"
if command -v python3 &> /dev/null; then
  echo "✓ Python 找到"
  python3 --version
else
  echo "✗ 未找到 Python"
fi
echo ""

# 2. 虚拟环境检查
echo "2️⃣ 虚拟环境检查"
echo "─────────────────────────────────────────────────"
if [ -d "lalc_backend/.venv" ]; then
  echo "✓ 虚拟环境已创建"
  VENV_PYTHON="lalc_backend/.venv/bin/python"
  if [ -f "$VENV_PYTHON" ]; then
    echo "  Python: $($VENV_PYTHON --version)"
  fi
else
  echo "✗ 虚拟环境未创建 - 请运行『一键安装.sh』"
fi
echo ""

# 3. 依赖包检查
echo "3️⃣ 依赖包检查"
echo "─────────────────────────────────────────────────"
if [ -d "lalc_backend/deps_macos" ]; then
  PKG_COUNT=$(ls lalc_backend/deps_macos/*.whl 2>/dev/null | wc -l)
  echo "✓ 找到 $PKG_COUNT 个依赖包"
elif [ -f "deps_macos.tar.gz" ]; then
  echo "✓ 找到 deps_macos.tar.gz（未解包）"
  echo "  → 运行『一键安装.sh』会自动解包"
else
  echo "✗ 未找到依赖包"
fi
echo ""

# 4. Flask/WebSocket 服务检查
echo "4️⃣ WebSocket 服务检查"
echo "─────────────────────────────────────────────────"
if [ -f "lalc_backend/.venv/bin/activate" ]; then
  source lalc_backend/.venv/bin/activate
  if python -c "import websockets" 2>/dev/null; then
    echo "✓ WebSocket 库可用"
  else
    echo "✗ WebSocket 库未安装"
  fi
  deactivate
else
  echo "✗ 虚拟环境未找到"
fi
echo ""

# 5. Flutter 检查
echo "5️⃣ Flutter 检查（可选，仅限开发者）"
echo "─────────────────────────────────────────────────"
if [ -d "tools/flutter" ]; then
  echo "✓ Flutter SDK 已安装"
  FLUTTER_VER=$(tools/flutter/bin/flutter --version 2>/dev/null | head -1 || echo "未知版本")
  echo "  $FLUTTER_VER"
elif command -v flutter &> /dev/null; then
  echo "✓ Flutter 已安装（系统全局）"
  flutter --version | head -1
else
  echo "⚠ Flutter 未安装（不影响后端运行）"
fi
echo ""

# 6. 常见问题诊断
echo "6️⃣ 常见问题诊断"
echo "─────────────────────────────────────────────────"

# 检查是否能访问摄像头权限
if [ -d "/Library/Application Support" ]; then
  echo "✓ macOS 系统兼容"
else
  echo "✗ 此脚本仅支持 macOS"
fi

# 检查磁盘空间
DISK_SPACE=$(df -h "$ROOT_DIR" | tail -1 | awk '{print $4}')
echo "✓ 本地磁盘可用空间: $DISK_SPACE"

echo ""
echo "════════════════════════════════════════════════"
echo ""
echo "诊断完成！"
echo ""
echo "如果看到很多 ✓，说明您的环境配置正常。"
echo ""
echo "❓ 遇到问题？"
echo ""
echo "常见问题："
echo "  1. Python 未找到 → 请安装 Xcode Command Line Tools"
echo "     运行: xcode-select --install"
echo ""
echo "  2. 依赖包未找到 → 确保 deps_macos.tar.gz 和源码在同一文件夹"
echo ""
echo "  3. 虚拟环境未创建 → 运行『一键安装.sh』"
echo ""
echo "  4. 权限问题 → 在『系统设置』→『隐私与安全性』中"
echo "     勾选『终端』的『屏幕录制』和『辅助功能』权限"
echo ""
