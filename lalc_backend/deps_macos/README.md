# 依赖包清单 (macOS)

**生成日期**: 2026-03-10  
**平台**: macOS (Apple Silicon arm64)  
**Python 版本**: 3.13 (兼容 3.10-3.13)  
**总文件数**: 41 个  
**总大小**: 171 MB

## 核心依赖

| 包名 | 版本 | 大小 | 说明 |
|------|------|------|------|
| onnxruntime | 1.24.3 | 17 MB | AI 推理引擎 |
| opencv-python-headless | 4.13.0.92 | 44 MB | 图像处理（无GUI） |
| opencv-python | 4.13.0.92 | 44 MB | 图像处理（完整版） |
| matplotlib | 3.10.8 | 7.8 MB | 数据可视化 |
| numpy | 2.4.3 | 5.0 MB | 数值计算 |
| scipy | 1.17.1 | 40 MB | 科学计算 |
| pillow | 12.1.1 | 4.4 MB | 图像处理 |
| pyobjc-framework-Quartz | 12.1 | 1.3 MB | macOS 窗口检测 |
| pyobjc-framework-Cocoa | 12.1 | 5.5 MB | macOS 接口 |
| pyobjc-core | 12.1 | 3.8 MB | PyObjC 核心 |
| websockets | 16.0 | 100 KB | WebSocket 服务器 |
| pynput | 1.8.1 | 68 KB | 输入控制 |
| rapidocr | 3.7.0 | 18 KB | OCR 识别 |
| psutil | 7.2.2 | 502 KB | 系统监控 |
| plyer | 2.1.0 | 147 KB | 系统通知 |

## 传递依赖

| 包名 | 版本 | 说明 |
|------|------|------|
| contourpy | 1.3.3 | 等高线绘制 |
| cycler | 0.12.1 | 样式循环 |
| fonttools | 4.62.0 | 字体工具 |
| kiwisolver | 1.5.0 | 布局求解器 |
| packaging | 26.0 | 版本解析 |
| pyparsing | 3.3.2 | 解析器 |
| python-dateutil | 2.9.0 | 日期处理 |
| shapely | 2.1.2 | 几何计算 |
| six | 1.17.0 | Python 2/3 兼容 |
| colorlog | 6.10.1 | 彩色日志 |
| flatbuffers | 25.12.19 | 序列化 |
| omegaconf | 2.3.0 | 配置管理 |
| antlr4-python3-runtime | 4.9.3 | 解析器运行时 |
| pyyaml | 6.0.3 | YAML 解析 |
| protobuf | 7.34.0 | Protocol Buffers |
| requests | 2.32.5 | HTTP 库 |
| charset-normalizer | 3.4.5 | 字符集检测 |
| idna | 3.11 | 国际化域名 |
| urllib3 | 2.6.3 | HTTP 客户端 |
| certifi | 2026.2.25 | CA 证书 |
| sympy | 1.14.0 | 符号计算 |
| mpmath | 1.3.0 | 多精度数学 |
| tqdm | 4.67.3 | 进度条 |
| pyclipper | 1.4.0 | 多边形裁剪 |
| pyobjc-framework-ApplicationServices | 12.1 | macOS 应用服务 |
| pyobjc-framework-CoreText | 12.1 | macOS 文本渲染 |

## 安装方法

### 离线安装（使用本地包）

```bash
pip install --no-index --find-links=deps_macos -r requirements-macos.txt
```

### 在线安装

```bash
pip install -r requirements-macos.txt
```

## 架构兼容性

- ✅ **Apple Silicon (M1/M2/M3)**: arm64 - 完全支持
- ⚠️ **Intel Mac**: x86_64 - 需要重新下载
- ❌ **Windows/Linux**: 不兼容（需要对应平台的包）

## 重新下载

如果需要为其他架构重新下载：

```bash
# Intel Mac
pip download --dest deps_macos_intel -r requirements-macos.txt \
    --platform macosx_10_9_x86_64 --python-version 3.12

# Universal (Intel + Apple Silicon)
pip download --dest deps_macos_universal -r requirements-macos.txt \
    --platform macosx_10_13_universal2 --python-version 3.12
```

## 校验和验证

生成 SHA256 校验和：

```bash
cd deps_macos
shasum -a 256 *.whl *.tar.gz > SHA256SUMS
```

验证完整性：

```bash
shasum -a 256 -c SHA256SUMS
```

---

**注意**: 此清单由自动化脚本生成，包版本可能根据下载时的 PyPI 最新版本有所变化。
