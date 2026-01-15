# Phase

> 一款 macOS 原生代理工具，专注于极致 UI 体验

## ✨ 特性

- 🎨 **精致 UI** - 遵循 macOS 设计规范，克制、优雅、系统融合度高
- ⚡️ **高性能** - SwiftUI 原生实现，低功耗、高响应
- 🔒 **隐私优先** - 本地运行，无数据上报
- 🌐 **sing-box 内核** - 支持主流代理协议
- 📊 **实时监控** - 流量统计、延迟测试

## 🏗️ 技术栈

- **平台**: macOS 14.0+
- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI
- **构建工具**: Swift Package Manager
- **代理内核**: sing-box

## 📁 项目结构

```
Sources/
├── PhaseApp.swift              # App 入口
├── AppDelegate.swift           # 菜单栏管理
├── Models/                     # 数据模型
│   └── ProxyModels.swift
├── ViewModels/                 # 状态管理
│   └── ProxyManager.swift
├── Views/                      # UI 层
│   ├── ContentView.swift       # 主窗口
│   ├── Overview/               # 总览页
│   │   └── OverviewView.swift
│   ├── Nodes/                  # 节点页
│   │   └── NodesView.swift
│   └── Components/             # 可复用组件
│       └── CommonComponents.swift
├── Services/                   # 业务逻辑
│   └── SingBoxService.swift
├── Utilities/                  # 工具类
│   └── Theme.swift
└── Resources/                  # 资源文件
    └── .gitkeep
```

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/ihoey/Phase
cd Phase
```

### 2. 安装 sing-box（可选）

Phase 会自动查找系统中的 sing-box 二进制文件。你可以通过以下方式安装：

```bash
# 使用 Homebrew
brew install sing-box

# 或手动下载
# 从 https://github.com/SagerNet/sing-box/releases 下载
# 将二进制文件放置到 /usr/local/bin/sing-box
```

### 3. 构建并运行

```bash
# 使用 Swift Package Manager
swift build

# 运行
swift run
```

或者在 Xcode 中打开项目：

```bash
# 生成 Xcode 项目
open Package.swift
```

## 🎯 当前进度

- [x] 项目基础架构
- [x] 设计系统与主题
- [x] 基础 UI 组件
- [x] 主窗口与导航
- [x] 总览页面（代理状态、流量统计、当前节点）
- [x] 节点页面（节点列表、延迟测试、搜索过滤）
- [x] 规则页面（规则组、规则列表、搜索过滤）
- [x] 日志页面（实时日志、级别过滤、自动滚动）
- [x] 设置页面（通用/代理/高级设置、关于）
- [x] 数据模型与 ViewModel
- [x] sing-box 集成（基础）
- [x] 系统代理自动切换
- [ ] 订阅管理
- [ ] 真实流量统计
- [ ] 自动更新

## 📸 预览

### 总览页面
- 大状态指示器（圆点 + 文字）
- 实时流量统计（上传/下载）
- 当前节点信息（名称、协议、延迟）
- 系统代理状态显示
- 快捷开关按钮

### 节点页面
- 节点列表展示（协议类型、延迟、服务器）
- 批量延迟测试（并发执行）
- 延迟颜色编码（绿/黄/红）
- 搜索过滤（名称/协议）
- 节点选择与切换

### 规则页面
- 左侧规则组列表
- 右侧规则详情展示
- 规则类型标签（域名/IP/GeoIP/GeoSite）
- 规则动作标识（代理/直连/拒绝）
- 搜索过滤规则

### 日志页面
- 实时日志流显示
- 日志级别过滤（TRACE/DEBUG/INFO/WARN/ERROR）
- 自动滚动开关
- 暂停/继续按钮
- 清空日志功能
- 搜索过滤日志

### 设置页面
- 通用设置（开机启动、自动更新）
- 代理设置（HTTP/SOCKS 端口、配置目录）
- 高级设置（日志级别、DNS 服务器、清除缓存）
- 关于信息（版本、内核、许可证）

## 🎨 设计原则

Phase 的设计遵循以下原则：

1. **UI 优先级 > 功能优先级** - 功能可以慢慢加，UI 一旦定型就很难推翻
2. **克制 > 炫技** - 不做赛博朋克，不做花哨渐变
3. **System-native · Calm · Confident · Precise** - 系统原生、平静、自信、精确

参考风格：
- macOS 系统设置
- Activity Monitor
- Raycast
- Arc Browser
- Linear

## 🔧 配置文件

配置文件存储在：
```
~/Library/Application Support/Phase/
├── phase-config.json    # Phase 配置
└── config.json          # sing-box 配置
```

## 🤝 贡献

欢迎贡献！请确保：
- 遵循 SwiftUI 最佳实践
- 保持 UI 克制、优雅
- 不破坏整体设计一致性

## 📄 许可证

MIT

---

**Phase** - 相信可以把 UI 做得更好 🚀
