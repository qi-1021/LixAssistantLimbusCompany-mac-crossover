#!/usr/bin/env bash
#
# LALC 一键启动脚本 - 前后端自动启动
# macOS 专用版本
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 清理函数
cleanup() {
  echo ""
  echo "${YELLOW}════════════════════════════════════════════════════${NC}"
  echo "${YELLOW}正在关闭 LALC 服务...${NC}"
  
  # 关闭后端进程
  if [ -f /tmp/lalc_backend.pid ]; then
    PID=$(cat /tmp/lalc_backend.pid 2>/dev/null || echo "")
    if [ -n "$PID" ]; then
      kill $PID 2>/dev/null || true
      wait $PID 2>/dev/null || true
      rm -f /tmp/lalc_backend.pid
      echo "${GREEN}✓ 后端服务已停止${NC}"
    fi
  fi
  
  echo "${YELLOW}════════════════════════════════════════════════════${NC}"
}

trap cleanup EXIT INT

# ==================== 环境检查 ====================
echo ""
echo "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo "${BLUE}║  LALC - Limbus Company 自动化助手（一键启动）      ║${NC}"
echo "${BLUE}║  需要您的 Limbus Company 游戏正在运行              ║${NC}"
echo "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# 检查虚拟环境
if [ ! -d "lalc_backend/.venv" ]; then
  echo "${RED}❌ 错误：虚拟环境不存在${NC}"
  echo "请先运行『一键安装.sh』或『自动配置Brew+Aria2.sh』"
  sleep 3
  exit 1
fi

# 激活虚拟环境
source lalc_backend/.venv/bin/activate

# 检查依赖
if ! python -c "import websockets" 2>/dev/null; then
  echo "${RED}❌ 错误：websockets 依赖未安装${NC}"
  echo "请先运行『一键安装.sh』重新安装依赖"
  sleep 3
  exit 1
fi

echo "${GREEN}✓ 环境检查通过${NC}"
echo ""

# ==================== 清理系统文件 ====================
echo "${BLUE}🧹 正在清理 macOS 系统文件...${NC}"
find . -name ".DS_Store" -delete 2>/dev/null || true
echo "${GREEN}✓ .DS_Store 已清理${NC}"
echo ""

# ==================== 检查游戏 ====================
echo "${BLUE}🔍 检查游戏状态...${NC}"
GAME_WINDOW=$(cd lalc_backend && python -c "
from utils.window_detector import get_limbus_window
win = get_limbus_window()
if win:
    print(f'检测到: {win.name} 位置: ({win.left},{win.top},{win.width}x{win.height})')
else:
    print('未检测到 Limbus Company 游戏窗口')
" 2>/dev/null || echo "未检测到游戏窗口（可能没有权限）")
echo "$GAME_WINDOW"
echo ""

# ==================== 启动后端 ====================
echo "${BLUE}🚀 启动后端服务...${NC}"
cd lalc_backend
mkdir -p logs
rm -f logs/server.log

# 启动后端在后台
python main.py > logs/server.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > /tmp/lalc_backend.pid
echo "后端进程 PID: ${GREEN}$BACKEND_PID${NC}"

# 等待后端启动
echo "${BLUE}⏳ 等待后端服务启动...${NC}"
for i in {1..30}; do
  if lsof -i :8765 >/dev/null 2>&1; then
    echo "${GREEN}✓ 后端服务已启动 (ws://localhost:8765)${NC}"
    sleep 1
    break
  fi
  echo -n "."
  sleep 0.3
  if [ $i -eq 30 ]; then
    echo ""
    echo "${RED}❌ 后端启动超时${NC}"
    echo "日志内容："
    tail -20 logs/server.log
    exit 1
  fi
done
echo ""

# ==================== 启动前端 ====================
echo "${BLUE}📱 启动前端应用...${NC}"
cd "$ROOT_DIR/lalc_frontend"

if [ ! -d "build/macos/Build/Products/Release/lalc_frontend.app" ]; then
  echo "${RED}❌ 前端应用不存在❌"
  echo "需要先编译: flutter build macos --release"
  exit 1
fi

open build/macos/Build/Products/Release/lalc_frontend.app
sleep 2
echo "${GREEN}✓ 前端应用已启动${NC}"
echo ""

# ==================== 显示使用提示 ====================
echo "${GREEN}════════════════════════════════════════════════════${NC}"
echo "${GREEN}✅ LALC 前后端已成功启动！${NC}"
echo "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo "📋 当前状态："
echo "   • 后端服务: ${GREEN}ws://localhost:8765 ( 运行中)${NC}"
echo "   • 前端应用: ${GREEN}已启动 (macOS 窗口)${NC}"
echo "   • 游戏检测: $GAME_WINDOW"
echo ""
echo "🎮 如何使用："
echo "   1. 打开『边狱巴士』游戏窗口"
echo "   2. 点击前端应用中的『开始自动化』或『半自动化』"
echo "   3. 后端将自动检测游戏窗口并执行操作"
echo "   4. 在『日志』窗口查看实时进度"
echo ""
echo "⚙️  高级选项："
echo "   • 日志位置: lalc_backend/logs/server.log"
echo "   • 配置文件: lalc_backend/config/"
echo "   • 要停止服务，直接关闭此终端窗口"
echo ""
echo "❓ 常见问题："
echo "   Q: 为什么无法自动操作游戏？"
echo "   A: 请确保："
echo "      1. Limbus Company 游戏已启动"
echo "      2. 终端已授予『屏幕录制』和『辅助功能』权限"
echo "      3. 『系统设置』→『隐私与安全性』中查看"
echo ""
echo "════════════════════════════════════════════════════"
echo ""

# ==================== 保持服务运行 ====================
wait $BACKEND_PID
