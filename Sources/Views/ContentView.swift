import SwiftUI

/// 导航分组
enum NavigationGroup: String, CaseIterable {
    case main = ""
    case proxy = "代理"
    case settings = "设置"
    case experimental = "实验"
}

/// 导航目标枚举
enum NavigationItem: String, CaseIterable, Identifiable {
    case overview = "概览"
    case traffic = "流量"
    case connections = "连接"
    case logs = "日志"
    case nodes = "节点"
    case rules = "规则"
    case resources = "资源"
    case config = "配置"
    case advanced = "高级"
    case topology = "拓扑"
    case subscriptions = "订阅"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "squares.leading.rectangle"
        case .traffic: return "chart.line.uptrend.xyaxis"
        case .connections: return "point.3.connected.trianglepath.dotted"
        case .logs: return "doc.text.magnifyingglass"
        case .nodes: return "server.rack"
        case .rules: return "list.bullet.indent"
        case .resources: return "externaldrive.connected.to.line.below"
        case .config: return "slider.horizontal.3"
        case .advanced: return "gearshape.2"
        case .topology: return "point.topleft.down.to.point.bottomright.curvepath"
        case .subscriptions: return "link.badge.plus"
        case .settings: return "gearshape"
        }
    }

    var group: NavigationGroup {
        switch self {
        case .overview, .traffic, .connections, .logs:
            return .main
        case .nodes, .rules, .resources, .subscriptions:
            return .proxy
        case .config, .advanced:
            return .settings
        case .topology:
            return .experimental
        case .settings:
            return .settings
        }
    }

    static var groupedItems: [(group: NavigationGroup, items: [NavigationItem])] {
        let groups: [NavigationGroup] = [.main, .proxy, .settings, .experimental]
        return groups.compactMap { group in
            let items = NavigationItem.allCases.filter { $0.group == group && $0 != .settings }
            if items.isEmpty { return nil }
            return (group, items)
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .overview
    @EnvironmentObject var proxyManager: ProxyManager

    var body: some View {
        NavigationSplitView(
            sidebar: {
                Sidebar(selectedItem: $selectedItem)
            },
            detail: {
                DetailView(selectedItem: selectedItem)
            }
        )
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            // 使用 principal 占位，确保其他项靠右
            ToolbarItem(placement: .principal) {
                Spacer()
            }

            // 通知
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 14))
                }
                .help("通知")
            }

            // 配置选择
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Default Config") {}
                    Button("Work Config") {}
                    Divider()
                    Button("导入配置...") {}
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9))
                        Text("Config")
                            .font(.system(size: 12))
                    }
                }
            }

            // 代理模式
            ToolbarItem(placement: .primaryAction) {
                Picker(
                    "模式",
                    selection: Binding(
                        get: { proxyManager.proxyMode },
                        set: { proxyManager.switchMode($0) }
                    )
                ) {
                    ForEach(ProxyMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            // 操作按钮组
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    // 系统代理
                    Button(action: { proxyManager.toggleSystemProxy() }) {
                        Image(
                            systemName: proxyManager.isSystemProxyEnabled
                                ? "globe" : "globe.badge.chevron.backward"
                        )
                        .font(.system(size: 16))
                        .foregroundColor(
                            proxyManager.isSystemProxyEnabled
                                ? Theme.Colors.statusActive : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("系统代理")
                    .disabled(!proxyManager.isRunning)

                    // 刷新
                    Button(action: {}) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .help("刷新连接")

                    // 电源开关
                    Button(action: { proxyManager.toggleProxy() }) {
                        Image(
                            systemName: proxyManager.isRunning
                                ? "bolt.circle.fill" : "bolt.circle"
                        )
                        .font(.system(size: 20, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(
                            proxyManager.isRunning ? Theme.Colors.statusActive : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(proxyManager.isRunning ? "停止代理" : "启动代理")
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

struct Sidebar: View {
    @Binding var selectedItem: NavigationItem
    @EnvironmentObject var proxyManager: ProxyManager

    var body: some View {
        VStack(spacing: 0) {
            // Logo 区域
            HStack(spacing: 10) {
                // Logo 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Phase")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)

            Divider()
                .padding(.horizontal, Theme.Spacing.md)

            // 分组导航列表
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(NavigationItem.groupedItems, id: \.group) { group, items in
                        VStack(alignment: .leading, spacing: 4) {
                            if !group.rawValue.isEmpty {
                                Text(group.rawValue)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.Colors.tertiaryText)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, Theme.Spacing.lg)
                                    .padding(.top, Theme.Spacing.md)
                                    .padding(.bottom, 4)
                            }

                            ForEach(items) { item in
                                SidebarButton(
                                    item: item,
                                    isSelected: selectedItem == item
                                ) {
                                    selectedItem = item
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
            }

            Spacer()

            Divider()
                .padding(.horizontal, Theme.Spacing.md)

            // 底部工具栏
            HStack(spacing: Theme.Spacing.lg) {
                // 关于按钮
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        Text("关于")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                .buttonStyle(.plain)

                Spacer()

                // 设置按钮
                Button(action: { selectedItem = .settings }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14))
                        Text("设置")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                }
                .buttonStyle(.plain)

                // 外部链接按钮
                Button(action: {}) {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
        .frame(minWidth: Theme.Layout.sidebarWidth)
    }
}

/// 侧边栏按钮
struct SidebarButton: View {
    let item: NavigationItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.Colors.secondaryText)
                    .frame(width: 20)

                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.sm)
    }
}

struct DetailView: View {
    let selectedItem: NavigationItem
    @StateObject private var trafficTracker = TrafficTracker()
    @EnvironmentObject var proxyManager: ProxyManager

    var body: some View {
        // 主内容
        Group {
            switch selectedItem {
            case .overview:
                OverviewView()
            case .nodes:
                NodesView()
            case .subscriptions:
                SubscriptionView()
            case .traffic:
                TrafficDetailView()
                    .environmentObject(trafficTracker)
                    .onAppear {
                        if trafficTracker.processes.isEmpty {
                            trafficTracker.addMockData()
                        }
                    }
            case .rules:
                RulesView()
            case .logs:
                LogsView()
            case .settings, .config, .advanced:
                SettingsView()
            case .connections:
                PlaceholderView(title: "连接", icon: "point.3.connected.trianglepath.dotted")
            case .resources:
                PlaceholderView(title: "资源", icon: "externaldrive.connected.to.line.below")
            case .topology:
                PlaceholderView(
                    title: "拓扑", icon: "point.topleft.down.to.point.bottomright.curvepath")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 占位视图 - 用于未实现的页面
struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.tertiaryText)

            Text(title)
                .font(Theme.Typography.title1)
                .foregroundColor(Theme.Colors.secondaryText)

            Text("此功能正在开发中")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 900, height: 600)
}
