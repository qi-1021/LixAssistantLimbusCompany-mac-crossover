#!/usr/bin/env bash
set -euo pipefail

# Wrapper for new offline installer
# This script preserves the original entrypoint for users and forwards
# arguments to `scripts/install_offline.sh`.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR"/.. && pwd)"

if [ ! -x "$ROOT_DIR/scripts/install_offline.sh" ]; then
  chmod +x "$ROOT_DIR/scripts/install_offline.sh" 2>/dev/null || true
fi

echo "使用新的离线安装脚本：scripts/install_offline.sh"
echo "示例： ./安装LALC-mac-离线.sh --create-venv --install-deps --install-flutter"

cd "$ROOT_DIR"
./scripts/install_offline.sh "$@"

