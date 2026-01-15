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
git clone <your-repo-url>
cd phase
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
- [x] 总览页面
- [x] 节点页面
- [x] 数据模型与 ViewModel
- [x] sing-box 集成（基础）
- [ ] 系统代理设置
- [ ] 规则管理
- [ ] 日志查看
- [ ] 订阅管理
- [ ] 设置页面
- [ ] 自动更新

## 📸 预览

### 总览页面
- 显示代理状态（启用/停止）
- 当前节点信息
- 实时流量统计
- 快捷开关按钮

### 节点页面
- 节点列表展示
- 延迟测试
- 节点切换
- 搜索过滤

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