# Phase - 开发指南

## 🎯 已完成功能

### ✅ 基础架构
- Swift Package Manager 项目结构
- macOS 原生 SwiftUI 应用
- 菜单栏常驻支持
- 窗口管理（隐藏标题栏）

### ✅ 设计系统
**Theme.swift** 提供完整的设计规范：
- **颜色系统**: 动态适配亮色/暗色模式
- **字体层级**: 从大标题到说明文本的完整体系
- **间距规范**: xs(4) → sm(8) → md(12) → lg(16) → xl(24) → xxl(32)
- **圆角规范**: sm(4) → md(8) → lg(12) → xl(16)
- **动画系统**: fast(0.15s) → standard(0.25s) → slow(0.35s) + spring

### ✅ UI 组件库
**CommonComponents.swift**：
- `CardView` - 统一卡片容器（带阴影和内边距）
- `StatusIndicator` - 状态指示器（圆点 + 文字）
- `NodeCell` - 节点单元格（已弃用，使用 NodeRow）
- `GlassBackground` - macOS 原生毛玻璃效果

### ✅ 主窗口架构
**ContentView.swift**：
- 侧边栏导航（总览/节点/规则/日志/设置）
- 分栏布局（NavigationSplitView）
- 底部状态栏（显示运行状态）
- 占位视图（未实现页面）

### ✅ 总览页面
**OverviewView.swift**：
- ✅ 状态卡片：大圆点指示器 + 启用/停止按钮
- ✅ 流量统计卡片：上传/下载实时显示（带图标和格式化单位）
- ✅ 当前节点卡片：节点名称、协议类型、延迟、服务器地址

### ✅ 节点页面
**NodesView.swift**：
- ✅ 搜索过滤：支持按名称和协议类型搜索
- ✅ 延迟测试：单个或批量测试所有节点
- ✅ 节点列表：显示选中状态、协议类型、延迟（带颜色编码）
- ✅ 空状态提示：暂无节点 / 未找到匹配节点

### ✅ 数据模型
**ProxyModels.swift**：
- `ProxyNode`: 节点模型（支持 SS/VMess/Trojan/Hysteria2/VLESS/TUIC）
- `TrafficStats`: 流量统计（字节 → 格式化显示）
- `ProxyConfig`: 配置模型（节点、选中状态、系统代理）

### ✅ 状态管理
**ProxyManager.swift**：
- 单例模式，全局状态管理
- 代理启动/停止控制
- 节点选择和切换
- 延迟测试（模拟和真实）
- 流量统计（定时器更新）
- 配置持久化（JSON 存储）

### ✅ sing-box 集成
**SingBoxService.swift**：
- 进程管理：启动/停止 sing-box
- 配置生成：动态生成 sing-box JSON 配置
- 日志输出：重定向标准输出用于调试
- 错误处理：完整的错误定义和处理
- 多路径查找：Resources → Homebrew → 系统路径

---

## 🚧 待完成功能

### 1. 系统代理设置
需要使用 `SystemConfiguration` 框架：
```swift
import SystemConfiguration

class SystemProxyManager {
    func setProxyEnabled(_ enabled: Bool, host: String, port: Int) {
        // 设置 HTTP/HTTPS/SOCKS 代理
    }
}
```

### 2. 规则管理页面
- 规则组展示（直连/代理/拒绝）
- 域名规则
- IP-CIDR 规则
- GeoIP/GeoSite 规则

### 3. 日志查看页面
- 实时日志流
- 日志级别过滤
- 日志搜索
- 日志导出

### 4. 订阅管理
- 订阅 URL 添加
- 自动更新
- 手动刷新
- 订阅信息显示

### 5. 设置页面
- 通用设置：开机启动、自动更新
- 代理设置：监听端口、绕过规则
- 高级设置：日志级别、DNS 服务器

---

## 🎨 UI 设计检查清单

### ✅ 已达成
- [x] 系统原生毛玻璃效果
- [x] SF Pro 字体体系
- [x] 动态颜色（支持亮色/暗色模式）
- [x] 大圆角卡片（12pt）
- [x] 微妙阴影
- [x] 克制的动画
- [x] 状态 0.5 秒可识别（大圆点 + 文字）
- [x] 信息层级清晰（每页一个问题）

### 🎯 需要优化
- [ ] 加载状态更优雅（骨架屏 vs 转圈）
- [ ] 错误提示更友好（Toast vs Alert）
- [ ] 微交互反馈（按钮点击、状态切换）

---

## 🔧 开发工作流

### 构建项目
```bash
swift build
```

### 运行应用
```bash
swift run
```

### 清理构建
```bash
swift package clean
```

### 生成 Xcode 项目
```bash
open Package.swift
```

---

## 📝 代码规范

### View 层
- 只负责展示，不包含业务逻辑
- 使用 `@EnvironmentObject` 获取状态
- 拆分子视图保持可读性

### ViewModel 层
- 负责状态管理和业务逻辑
- 使用 `@Published` 暴露状态
- 异步操作使用 `async/await`

### Service 层
- 封装外部依赖（sing-box、系统代理）
- 单例模式
- 错误处理完整

### 命名规范
- View: `XxxView`
- ViewModel: `XxxManager` / `XxxViewModel`
- Service: `XxxService`
- Model: 直接使用名词（`ProxyNode`, `TrafficStats`）

---

## 🐛 已知问题

### 1. sing-box 二进制缺失
**现象**：启动代理时报错 "未找到 sing-box 二进制文件"

**解决方案**：
```bash
# 方案 1: 使用 Homebrew 安装
brew install sing-box

# 方案 2: 手动下载
# 从 https://github.com/SagerNet/sing-box/releases 下载
# 放置到 /usr/local/bin/sing-box
# 添加执行权限: chmod +x /usr/local/bin/sing-box
```

### 2. 配置文件格式问题
**现象**：sing-box 启动失败

**解决方案**：
- 检查 `~/Library/Application Support/Phase/config.json`
- 确保符合 sing-box 配置格式
- 查看终端输出的 sing-box 日志

### 3. 流量统计为模拟数据
**现象**：流量统计不准确

**说明**：当前使用随机数模拟，真实实现需要：
- sing-box API 查询
- 或解析 sing-box 日志

---

## 📚 参考资源

### sing-box 文档
- [配置格式](https://sing-box.sagernet.org/configuration/)
- [协议支持](https://sing-box.sagernet.org/configuration/outbound/)
- [路由规则](https://sing-box.sagernet.org/configuration/route/)

### macOS 开发
- [SwiftUI 官方文档](https://developer.apple.com/xcode/swiftui/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

### 设计参考
- macOS 系统设置
- Activity Monitor
- Raycast
- Arc Browser

---

## 🚀 下一步计划

1. **系统代理集成** (高优先级)
   - 启用代理时自动设置系统代理
   - 停用时恢复原设置

2. **真实流量统计** (高优先级)
   - 从 sing-box 获取真实数据
   - 历史流量图表

3. **订阅支持** (中优先级)
   - 解析主流订阅格式
   - 定时自动更新

4. **规则管理** (中优先级)
   - 可视化规则编辑
   - 规则测试工具

5. **日志查看** (低优先级)
   - 实时日志流
   - 日志级别切换

---

**Phase** - 专注于 UI 体验的 macOS 代理工具 🚀
