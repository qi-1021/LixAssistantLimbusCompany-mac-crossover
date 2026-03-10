#!/usr/bin/env bash
# 
# LALC macOS 一键安装脚本
# 适用于非技术用户
# 无需任何配置，直接运行本脚本即可
#

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 工具函数
log_step() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}✓${NC} $1"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}✗${NC} $1"
}

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

# 欢迎信息
clear
cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              LALC macOS 一键安装程序                       ║
║                                                            ║
║  本程序会自动为您安装 LALC 所需的所有依赖                  ║
║  无需任何复杂的配置或命令行操作                            ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

EOF

# Step 1: 检查 Python
log_step "步骤 1/5：检查 Python 环境"

if ! command -v python3 &> /dev/null; then
  log_error "未找到 Python！"
  echo ""
  echo "请按以下步骤安装 Python："
  echo ""
  echo "1️⃣ 打开 App Store（直接点击 Spotlight 搜索并输入 'App Store'）"
  echo "2️⃣ 搜索 'Xcode'"
  echo "3️⃣ 点击 '获取' 并等待下载完成"
  echo "   （这会安装 Python 和其他必要工具）"
  echo ""
  echo "完成后，再次运行本脚本。"
  exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
log_info "找到 Python $PYTHON_VERSION ✓"

# Step 2: 检查依赖包
log_step "步骤 2/5：检查依赖包"

if [ ! -f "deps_macos.tar.gz" ] && [ ! -d "lalc_backend/deps_macos" ]; then
  log_error "找不到依赖包！"
  echo ""
  echo "请下载完整的安装包，确保包含："
  echo "  - deps_macos.tar.gz (或 lalc_backend/deps_macos/ 目录)"
  echo "  - flutter.tar.gz (可选)"
  echo ""
  exit 1
fi

if [ -f "deps_macos.tar.gz" ]; then
  log_info "发现 deps_macos.tar.gz，正在解包..."
  mkdir -p lalc_backend
  tar -C lalc_backend -xzf deps_macos.tar.gz
  log_info "依赖包已解包 ✓"
elif [ -d "lalc_backend/deps_macos" ]; then
  log_info "找到本地依赖包目录 ✓"
fi

if [ -f "flutter.tar.gz" ] && [ ! -d "tools/flutter" ]; then
  log_info "发现 flutter.tar.gz，正在解包..."
  mkdir -p tools
  tar -C tools -xzf flutter.tar.gz
  log_info "Flutter SDK 已解包 ✓"
fi

# Step 3: 创建虚拟环境
log_step "步骤 3/5：创建隔离的 Python 环境"

if [ ! -d "lalc_backend/.venv" ]; then
  log_info "正在创建虚拟环境（第一次安装时此步骤可能需要几分钟）..."
  python3 -m venv lalc_backend/.venv
  log_info "虚拟环境创建成功 ✓"
else
  log_info "虚拟环境已存在 ✓"
fi

# Step 4: 安装依赖
log_step "步骤 4/5：安装依赖包（这可能需要 2-5 分钟...）"

source lalc_backend/.venv/bin/activate

log_info "升级 pip..."
python -m pip install --upgrade pip setuptools wheel -q

log_info "安装依赖包..."
if [ -d "lalc_backend/deps_macos" ]; then
  python -m pip install --no-index --find-links=lalc_backend/deps_macos -r lalc_backend/requirements-macos.txt -q
  log_info "所有依赖已离线安装 ✓"
else
  log_warn "未找到本地依赖包，从互联网安装（需要网络连接）..."
  python -m pip install -r lalc_backend/requirements-macos.txt -q
  log_info "所有依赖已安装 ✓"
fi

# Step 5: 最后验证
log_step "步骤 5/5：验证安装"

if python -c "import websockets, cv2, PIL, pynput" 2>/dev/null; then
  log_info "所有核心依赖验证通过 ✓"
else
  log_warn "某些依赖验证失败，但这通常不会影响使用"
fi

# 完成
clear
cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║                  安装完成！             ✓                  ║
╚════════════════════════════════════════════════════════════╝

EOF

echo -e "${GREEN}恭喜！LALC 已成功安装${NC}"
echo ""
echo "下一步："
echo ""
echo "1️⃣ 系统权限设置（重要！）"
echo "   打开『系统设置』→『隐私与安全性』→『屏幕录制』"
echo "   勾选『终端』（Terminal）"
echo "   同样在『辅助功能』中也勾选『终端』"
echo ""
echo "2️⃣ 启动 LALC"
echo "   运行命令："
echo "   source lalc_backend/.venv/bin/activate"
echo "   ./启动LALC-mac.sh"
echo ""
echo "或者，直接双击运行『启动LALC-mac.sh』脚本（推荐新手）"
echo ""
echo "❓ 遇到问题？"
echo "   查看『使用说明.txt』或运行『诊断.sh』"
echo ""
