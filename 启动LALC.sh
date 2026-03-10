#!/usr/bin/env bash
#
# LALC 启动脚本 - 同时启动前后端
# 支持同时运行 macOS 前端和 Python 后端
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

# 定义颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 存储后端 PID，以便最后清理
BACKEND_PID=""
cleanup() {
  if [ -n "$BACKEND_PID" ]; then
    echo ""
    echo "${YELLOW}正在关闭后端服务...${NC}"
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
    echo "${GREEN}后端服务已停止${NC}"
  fi
}
trap cleanup EXIT

# 错误处理函数
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
echo "║            LALC - Limbus Company 自动化助手           ║"
echo "║         正在启动前后端服务（前端 + 后端）...          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 清理 macOS 系统文件
echo "🧹 清理 macOS 系统文件..."
find . -name ".DS_Store" -delete 2>/dev/null || true
echo "${GREEN}✓ .DS_Store 已清理${NC}"
echo ""

# 检查系统权限提示
echo "📋 系统权限检查："
echo "  如果看到权限请求，请点击『允许』"
echo "  （您可能需要在『系统设置』→『隐私与安全性』中"
echo "   为『终端』授予『屏幕录制』和『辅助功能』权限）"
echo ""

# 启动后端服务（后台）
echo "🚀 启动 LALC 后端服务（WebSocket 服务器 ws://localhost:8765）..."
cd lalc_backend

# 清理日志目录
mkdir -p logs
rm -f logs/server.log

# 在后台启动后端
python main.py > logs/server.log 2>&1 &
BACKEND_PID=$!
echo "   后端进程 PID: $BACKEND_PID"

# 等待后端监听端口
echo "⏳ 等待后端服务启动..."
for i in {1..20}; do
  if lsof -i :8765 >/dev/null 2>&1; then
    echo "${GREEN}✓ 后端服务已启动，监听 ws://localhost:8765${NC}"
    break
  fi
  sleep 0.5
  if [ $i -eq 20 ]; then
    echo "${RED}✗ 后端服务启动超时，请检查日志：${NC}"
    tail -20 logs/server.log
    exit 1
  fi
done

echo ""
echo "📱 启动 LALC 前端应用..."
cd "$ROOT_DIR/lalc_frontend"

# 启动 Flutter 应用
FRONTEND_APP=""
if [ -d "build/macos/Build/Products/Release/lalc_frontend.app" ]; then
  FRONTEND_APP="build/macos/Build/Products/Release/lalc_frontend.app"
elif [ -d "build/macos/Build/Products/Debug/lalc_frontend.app" ]; then
  FRONTEND_APP="build/macos/Build/Products/Debug/lalc_frontend.app"
else
  echo "${RED}✗ 未找到前端应用，请先构建 macOS 前端${NC}"
  exit 1
fi

open "$FRONTEND_APP" &
FRONTEND_PID=$!
echo "${GREEN}✓ 前端应用已启动${NC}"

echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ LALC 前后端服务已启动"
echo ""
echo "详情："
echo "  • 后端服务: ws://localhost:8765"
echo "  • 前端应用: $FRONTEND_APP"
echo "  • 日志位置: lalc_backend/logs/server.log"
echo ""
echo "提示："
echo "  • 在『边狱巴士』游戏窗口启动后，点击『开始自动化』"
echo "  • 关闭此终端窗口将停止后端服务和前端应用"
echo "════════════════════════════════════════════════════════"
echo ""

# 等待后端进程
wait $BACKEND_PID 2>/dev/null || true

# 脚本结束
echo ""
echo "════════════════════════════════════════════════════════"
echo "⏹️  LALC 已关闭"
echo "════════════════════════════════════════════════════════"
