# LALC macOS 使用指南

LixAssistantLimbusCompany (LALC) 的 macOS 跨平台版本。

本版本为原Windows版项目的macOS移植版，实现了纯macOS原生运行，无需Wine/CrossOver等兼容层。同时也支持检测CrossOver中运行的Windows游戏窗口。

## 📋 系统要求

- **操作系统**: macOS 10.13+ (推荐 macOS 12+)
- **Python**: 3.10 或更高版本
- **权限**: 屏幕录制 + 辅助功能权限
- **(可选) Flutter**: 3.9.2+ (仅编译前端时需要)

## 🚀 快速开始

### 1. 安装 Python 依赖

```bash
cd LixAssistantLimbusCompany-master/lalc_backend
pip install -e .
```

如果使用 conda:
```bash
conda create -n lalc python=3.12
conda activate lalc
pip install -e .
```

### 2. 授予系统权限

首次运行前，需要授予以下权限：

1. 打开 **系统设置 → 隐私与安全性 → 屏幕录制**
   - 添加并勾选 `终端.app` (或你使用的终端应用)
   
2. 打开 **系统设置 → 隐私与安全性 → 辅助功能**
   - 添加并勾选 `终端.app` (或你使用的终端应用)

> ⚠️ 首次运行时系统会弹窗请求权限，授予后需要重启程序才能生效。

### 3. 启动后端服务器

```bash
cd LixAssistantLimbusCompany-master
./启动LALC-mac.sh
```

成功启动后会显示：
```
使用 Python: /path/to/python (版本 3.12)
========================================
LALC macOS 启动器
========================================
✓ 自动检测到游戏窗口: left=100, top=200, width=1302, height=776

WebSocket 服务器启动，监听 ws://localhost:8765
```

## 🎮 窗口检测模式

LALC 支持三种窗口配置方式（按优先级排序）：

### 模式 1: 自动检测（推荐）

启动时会自动搜索包含 "LimbusCompany" 或 "CrossOver" 的窗口：

```bash
./启动LALC-mac.sh
# 会自动检测CrossOver中的游戏窗口
```

### 模式 2: 手动指定环境变量

如果自动检测失败，可以手动指定窗口坐标：

```bash
export LALC_WINDOW_LEFT=100    # 窗口左边界
export LALC_WINDOW_TOP=200     # 窗口上边界
export LALC_WINDOW_WIDTH=1302  # 窗口宽度
export LALC_WINDOW_HEIGHT=776  # 窗口高度

./启动LALC-mac.sh
```

### 模式 3: 使用窗口检测工具

提供了命令行工具来查找窗口坐标：

```bash
cd lalc_backend

# 列出所有窗口
python -m utils.window_detector --list

# 检测特定窗口
python -m utils.window_detector --detect "LimbusCompany"
```

输出示例：
```
找到窗口:
  LALC_WINDOW_LEFT=100
  LALC_WINDOW_TOP=200
  LALC_WINDOW_WIDTH=1302
  LALC_WINDOW_HEIGHT=776

可以这样使用:
  export LALC_WINDOW_LEFT=100 LALC_WINDOW_TOP=200 LALC_WINDOW_WIDTH=1302 LALC_WINDOW_HEIGHT=776
```

## 🖥️ CrossOver 专用配置

如果游戏运行在 CrossOver 中：

1. **先启动游戏**（在 CrossOver 中打开 LimbusCompany）
2. **再启动 LALC**（会自动检测 CrossOver 窗口）

如果检测失败：
```bash
# 使用工具找到CrossOver窗口坐标
python -m utils.window_detector --list | grep -i crossover

# 手动设置环境变量后启动
export LALC_WINDOW_LEFT=... LALC_WINDOW_TOP=...
./启动LALC-mac.sh
```

## 🎨 编译前端 (可选)

后端可以独立运行（通过 WebSocket API 使用），如需完整的 GUI 界面：

### 1. 安装 Flutter

```bash
# 下载 Flutter SDK (推荐使用 git)
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable

# 添加到 PATH
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# 验证安装
flutter doctor
```

### 2. 配置 macOS 工具链

```bash
# 安装 CocoaPods (Flutter macOS 编译需要)
sudo gem install cocoapods

# 运行 Flutter 诊断
flutter doctor
```

### 3. 编译前端

```bash
cd lalc_frontend

# 获取依赖
flutter pub get

# 编译 macOS 应用
flutter build macos --release

# 编译完成后，应用位于：
# lalc_frontend/build/macos/Build/Products/Release/lalc_frontend.app
```

### 4. 运行前端

```bash
# 方式 1: 直接运行构建产物
open lalc_frontend/build/macos/Build/Products/Release/lalc_frontend.app

# 方式 2: 开发模式运行（支持热重载）
cd lalc_frontend
flutter run -d macos
```

## 🔧 故障排查

### 问题 1: 截图一片黑 / 无法识别游戏

**原因**: 未授予屏幕录制权限

**解决**:
1. 系统设置 → 隐私与安全性 → 屏幕录制
2. 勾选终端应用
3. 重启 LALC

### 问题 2: 无法控制鼠标/键盘

**原因**: 未授予辅助功能权限

**解决**:
1. 系统设置 → 隐私与安全性 → 辅助功能
2. 勾选终端应用
3. 重启 LALC

### 问题 3: 找不到窗口

**原因**: 游戏未运行 或 窗口标题不匹配

**解决**:
```bash
# 1. 确认游戏正在运行
# 2. 使用工具列出所有窗口
python -m utils.window_detector --list

# 3. 找到游戏窗口后，手动设置环境变量
export LALC_WINDOW_LEFT=... LALC_WINDOW_TOP=...
```

### 问题 4: Python 版本过低

**原因**: 需要 Python 3.10+

**解决**:
```bash
# 使用 Homebrew 安装新版 Python
brew install python@3.12

# 或使用 conda
conda install python=3.12
```

### 问题 5: 缺少依赖

**错误**: `ModuleNotFoundError: No module named 'XXX'`

**解决**:
```bash
cd lalc_backend
pip install -e .  # 重新安装依赖
```

### 问题 6: 无法检测 CrossOver 窗口

**原因**: `pyobjc-framework-Quartz` 未安装

**解决**:
```bash
pip install pyobjc-framework-Quartz
```

## 📚 技术架构

### 后端 (Python)

- **平台检测**: 自动识别 Windows/macOS 并加载对应适配器
- **输入控制**: 
  - Windows: `pywin32` (win32api, win32gui)
  - macOS: `pynput` + `PIL.ImageGrab`
- **截图引擎**:
  - Windows: `PrintWindow` API (可截取DirectX游戏)
  - macOS: `ImageGrab.grab(bbox)` (基于 Quartz)
- **窗口检测**: `pyobjc-framework-Quartz` (CGWindowListCopyWindowInfo)
- **自动化框架**: `onnxruntime` + `opencv` (模板匹配)

### 前端 (Flutter)

- **跨平台 UI**: Flutter 3.9.2+
- **通信协议**: WebSocket (连接到 `ws://localhost:8765`)
- **窗口管理**: `window_manager` (支持自定义窗口大小/位置)

## 🌍 与其他用户分享

### 作为开发者发布

1. **清理个人信息**:
   - ✅ 已移除硬编码路径 (启动脚本使用智能检测)
   - ✅ 已使用环境变量配置 (无个人数据)
   - ✅ 依赖配置通用化 (pyproject.toml 平台条件依赖)

2. **打包发布**:
   ```bash
   # 创建源码包
   cd LixAssistantLimbusCompany-master
   tar -czf LALC-macOS-v1.0.tar.gz \
       lalc_backend/ lalc_frontend/ \
       启动LALC-mac.sh README_macOS.md \
       LICENSE README.md
   ```

3. **提交到 GitHub**:
   ```bash
   git add .
   git commit -m "Add macOS support with auto-detection"
   git push origin macos-support
   ```

### 作为用户使用

其他 macOS 用户只需：

1. 下载发布包
2. 安装 Python 依赖: `pip install -e lalc_backend`
3. 运行启动脚本: `./启动LALC-mac.sh`

无需任何个人配置，一键启动。

## ⚠️ 安全注意事项

1. **权限最小化**: 仅请求必要的系统权限（屏幕录制、辅助功能）
2. **本地运行**: WebSocket 服务器只监听 `localhost`，不暴露到外网
3. **无数据收集**: 不上传任何游戏数据或个人信息
4. **开源透明**: 所有代码可审查，无混淆/加密逻辑

## 📞 获取帮助

- **GitHub Issues**: [项目仓库 Issues 页面](https://github.com/HSLix/LixAssistantLimbusCompany/issues)
- **查看日志**: 运行时会输出详细日志，包括窗口检测、截图状态等
- **调试模式**: 设置 `export DEBUG=1` 启用详细调试输出

## 📄 许可证

本项目遵循原项目的许可证。macOS 移植部分使用相同许可证发布。

---

**版本**: 1.0.0 (macOS 移植版)  
**最后更新**: 2026-03-10  
**移植作者**: AI Assistant
