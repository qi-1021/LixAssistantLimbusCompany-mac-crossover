#!/usr/bin/env bash
set -euo pipefail

# package_deps.sh
# 将大型依赖打包为独立归档：
# - tools/flutter -> flutter.tar.gz
# - lalc_backend/deps_macos -> deps_macos.tar.gz
# 运行位置：项目根目录

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "项目根: $ROOT_DIR"

if [ -d "tools/flutter" ]; then
  echo "打包 Flutter SDK -> flutter.tar.gz"
  tar -C tools -czf flutter.tar.gz flutter
else
  echo "警告：未找到 tools/flutter，跳过 Flutter 打包"
fi

if [ -d "lalc_backend/deps_macos" ]; then
  echo "打包 Python 依赖 -> deps_macos.tar.gz"
  tar -C lalc_backend -czf deps_macos.tar.gz deps_macos
else
  echo "警告：未找到 lalc_backend/deps_macos，跳过 deps 打包"
fi

echo "打包完成。生成的文件位于:"
ls -lh flutter.tar.gz deps_macos.tar.gz 2>/dev/null || true

echo "提示：将这些归档放到 Releases 或和源码一起分发。"
