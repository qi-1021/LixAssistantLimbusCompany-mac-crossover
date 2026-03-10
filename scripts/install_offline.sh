#!/usr/bin/env bash
set -euo pipefail

# install_offline.sh
# 目的：使用本地离线归档安装 LALC（backend 依赖、Flutter SDK 可选）
# 预期目录结构：
# - 项目根/
#   - scripts/install_offline.sh
#   - flutter.tar.gz (可选)
#   - deps_macos.tar.gz
#
# 用法：在项目根运行：
#   sudo ./scripts/install_offline.sh --install-deps --install-flutter

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

show_help(){
  cat <<EOF
usage: $0 [--install-deps] [--install-flutter] [--create-venv]

Options:
  --install-deps     : 从 deps_macos.tar.gz 解包并安装 Python 依赖到虚拟环境
  --install-flutter  : 从 flutter.tar.gz 解包到 ./tools/flutter（可选）
  --create-venv      : 在 lalc_backend/.venv 创建 Python 虚拟环境
  -h, --help         : 显示帮助
EOF
}

INSTALL_DEPS=0
INSTALL_FLUTTER=0
CREATE_VENV=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-deps) INSTALL_DEPS=1; shift ;;
    --install-flutter) INSTALL_FLUTTER=1; shift ;;
    --create-venv) CREATE_VENV=1; shift ;;
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown arg: $1"; show_help; exit 1 ;;
  esac
done

if [ "$INSTALL_FLUTTER" -eq 1 ]; then
  if [ -f flutter.tar.gz ]; then
    echo "解包 flutter.tar.gz -> ./tools/"
    mkdir -p tools
    tar -C tools -xzf flutter.tar.gz
    echo "Flutter 已解包到 tools/flutter"
  else
    echo "未找到 flutter.tar.gz，跳过 Flutter 解包。若需要，请把归档放到项目根。"
  fi
fi

if [ "$CREATE_VENV" -eq 1 ]; then
  echo "创建虚拟环境在 lalc_backend/.venv"
  python3 -m venv lalc_backend/.venv
  echo "虚拟环境创建完成。要激活： source lalc_backend/.venv/bin/activate"
fi

if [ "$INSTALL_DEPS" -eq 1 ]; then
  if [ ! -f deps_macos.tar.gz ]; then
    echo "错误：未找到 deps_macos.tar.gz（请把归档放到项目根）。"; exit 1
  fi

  echo "解包 deps_macos.tar.gz 到 lalc_backend/deps_macos"
  mkdir -p lalc_backend
  tar -C lalc_backend -xzf deps_macos.tar.gz

  VENV_ACTIVATE=""
  if [ -f lalc_backend/.venv/bin/activate ]; then
    VENV_ACTIVATE="source lalc_backend/.venv/bin/activate"
  else
    echo "未检测到虚拟环境。将使用系统 Python（建议使用 --create-venv 创建虚拟环境）。"
  fi

  echo "开始安装 wheels..."
  if [ -n "$VENV_ACTIVATE" ]; then
    bash -lc "$VENV_ACTIVATE && python -m pip install --upgrade pip setuptools wheel && pip install --no-index --find-links=lalc_backend/deps_macos -r lalc_backend/requirements-macos.txt"
  else
    python3 -m pip install --upgrade pip setuptools wheel
    python3 -m pip install --no-index --find-links=lalc_backend/deps_macos -r lalc_backend/requirements-macos.txt
  fi

  echo "Python 依赖安装完成。"
fi

echo "离线安装脚本执行完毕。下一步：配置环境变量并运行启动脚本。例如："
cat <<EOF
export PATH=")$(pwd)/tools/flutter/bin:$PATH"
# 激活 venv（如果创建了）:
# source lalc_backend/.venv/bin/activate
# 然后运行后端：
# LALC_WINDOW_LEFT=... LALC_WINDOW_TOP=... ./启动LALC-mac.sh
EOF
