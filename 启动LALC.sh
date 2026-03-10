#!/usr/bin/env bash
#
# LALC 启动脚本（简化版，无需手动激活虚拟环境）
# 用户可以直接双击运行此文件
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 错误处理
show_error() {
  echo ""
  echo "╔════════════════════════════════════════════════════════╗"
  echo "║                      ❌ 错误                            ║"
  echo "╚════════════════════════════════════════════════════════╝"
  echo ""
  echo "错误信息："
  echo "$1"
  echo ""
  echo "解决方案："
  echo "1. 确保您已运行『一键安装.sh』"
  echo "2. 运行『诊断.sh』以检查环境"
  echo "3. 查看『使用说明.txt』获取帮助"
  echo ""
  read -p "按 Enter 键关闭此窗口..."
  exit 1
}

# 检查虚拟环境
if [ ! -d "lalc_backend/.venv" ]; then
  show_error "虚拟环境不存在。请先运行『一键安装.sh』"
fi

# 激活虚拟环境
source lalc_backend/.venv/bin/activate

# 检查依赖
if ! python -c "import websockets" 2>/dev/null; then
  show_error "依赖未正确安装。请重新运行『一键安装.sh'"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                   LALC 正在启动...                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 检查系统权限提示
echo "📋 系统权限检查："
echo "  如果看到权限请求，请点击『允许』"
echo "  （您可能需要在『系统设置』→『隐私与安全性』中"
echo "   为『终端』授予『屏幕录制』和『辅助功能』权限）"
echo ""

# 获取窗口信息
echo "🔍 检测到的窗口信息："
WINDOW_INFO=$(cd lalc_backend && python -m utils.window_detector --detect "LimbusCompany" 2>/dev/null || echo "未找到窗口")
echo "$WINDOW_INFO"
echo ""

# 启动后端服务
echo "🚀 启动 LALC 后端服务（WebSocket 服务器）..."
echo ""

cd lalc_backend
python main.py

# 如果到这里表示服务已停止
echo ""
echo "════════════════════════════════════════════════════════"
echo "LALC 已关闭"
echo "════════════════════════════════════════════════════════"
read -p "按 Enter 键关闭此窗口..."
