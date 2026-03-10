# LALC macOS 快速开始

> **LixAssistantLimbusCompany** 的 macOS 跨平台版本

## 🚀 一键安装

### 方式 1: 在线安装（推荐）

```bash
# 1. 下载项目
git clone https://github.com/HSLix/LixAssistantLimbusCompany.git
cd LixAssistantLimbusCompany

# 2. 运行安装脚本
./安装LALC-mac.sh

# 3. 启动程序
./启动LALC-mac.sh
```

### 方式 2: 离线安装（无需网络）

如果你的电脑无法访问 PyPI 或网络受限：

```bash
# 1. 下载完整离线包（包含 171MB 依赖）
# 解压到本地

# 2. 运行离线安装脚本
./安装LALC-mac-离线.sh

# 3. 启动程序
./启动LALC-mac.sh
```

**说明**: 离线包已包含 41 个依赖包在 `lalc_backend/deps_macos/` 目录中。

## ✨ 特性

- ✅ **纯 macOS 原生运行**（无需 Wine/CrossOver）
- ✅ **自动检测 CrossOver 游戏窗口**（也支持检测CrossOver中的游戏）
- ✅ **零配置启动**（自动查找 Python 环境）
- ✅ **通用化设计**（无硬编码路径，可直接分享）
- ✅ **离线安装支持**（包含完整依赖包，171MB）

## 🎯 CrossOver 用户

如果你在 CrossOver 中运行游戏：

```bash
# 1. 先启动游戏（在 CrossOver 中打开 LimbusCompany）
# 2. 再启动 LALC（会自动检测游戏窗口）
./启动LALC-mac.sh
```

输出示例：
```
✓ 自动检测到游戏窗口: left=2, top=39, width=891, height=518
WebSocket 服务器启动，监听 ws://localhost:8765
```

## 📖 完整文档

详细使用说明请查看：[README_macOS.md](README_macOS.md)

包含：
- 手动配置窗口坐标
- 故障排查指南
- Flutter 前端编译
- 技术架构说明

## ⚠️ 权限要求

首次运行需要授予权限：

1. **系统设置 → 隐私与安全性 → 屏幕录制** ✓
2. **系统设置 → 隐私与安全性 → 辅助功能** ✓

> 授予权限后需重启程序

## 🔧 故障排查

**问题：截图一片黑**  
→ 检查屏幕录制权限

**问题：无法控制鼠标**  
→ 检查辅助功能权限

**问题：找不到窗口**  
→ 使用检测工具：
```bash
cd lalc_backend
python -m utils.window_detector --list
```

## 📦 依赖

- Python 3.10+
- macOS 10.13+ (推荐 macOS 12+)

所有依赖会自动安装：
- pynput (鼠标/键盘控制)
- Pillow (截图)
- pyobjc-framework-Quartz (窗口检测)
- websockets (通信协议)
- onnxruntime + opencv (自动化引擎)

## 💡 提示

**只用后端** (无需前端 GUI):
```bash
./启动LALC-mac.sh
# 后端 WebSocket API: ws://localhost:8765
```

**编译前端** (完整 GUI):
```bash
# 安装 Flutter
brew install flutter

# 编译前端
cd lalc_frontend
flutter pub get
flutter build macos
```

---

**版本**: 1.0.0-macOS  
**原项目**: [HSLix/LixAssistantLimbusCompany](https://github.com/HSLix/LixAssistantLimbusCompany)
