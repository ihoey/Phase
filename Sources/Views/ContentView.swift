import SwiftUI

/// 导航分组
enum NavigationGroup: String, CaseIterable {
    case main = ""
    case proxy = "代理"
    case settings = "设置"
}

/// 导航目标枚举
enum NavigationItem: String, CaseIterable, Identifiable {
    case overview = "概览"
    case traffic = "流量"
    case connections = "连接"
    case logs = "日志"
    case nodes = "节点"
    case rules = "规则"
    case config = "配置"
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
        case .config: return "slider.horizontal.3"
        case .subscriptions: return "link.badge.plus"
        case .settings: return "gearshape"
        }
    }

    var group: NavigationGroup {
        switch self {
        case .overview, .traffic, .connections, .logs:
            return .main
        case .nodes, .rules, .subscriptions:
            return .proxy
        case .config:
            return .settings
        case .settings:
            return .settings
        }
    }

    static var groupedItems: [(group: NavigationGroup, items: [NavigationItem])] {
        let groups: [NavigationGroup] = [.main, .proxy, .settings]
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
                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)

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
            HStack(spacing: Theme.Spacing.sm) {
                // 关于按钮
                SidebarFooterButton(icon: "info.circle", tooltip: "关于") {}

                Spacer()

                // 设置按钮
                SidebarFooterButton(
                    icon: selectedItem == .settings ? "gearshape.fill" : "gearshape",
                    tooltip: "设置",
                    isActive: selectedItem == .settings
                ) {
                    selectedItem = .settings
                }

                // 外部链接按钮
                SidebarFooterButton(icon: "arrow.up.forward.square", tooltip: "GitHub") {
                    if let url = URL(string: "https://github.com/ihoey/Phase") {
                        NSWorkspace.shared.open(url)
                    }
                }
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

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(
                        isSelected
                            ? .white
                            : (isHovered ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
                    )
                    .frame(width: 20)
                    .symbolEffect(.bounce, value: isSelected)

                Text(item.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)

                Spacer()

                // 徽章显示（可选）
                if let badge = badgeCount {
                    Text("\(badge)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(
                            isSelected ? .white.opacity(0.9) : Theme.Colors.secondaryText
                        )
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    isSelected
                                        ? Color.white.opacity(0.2)
                                        : Theme.Colors.separator.opacity(0.5))
                        )
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isHovered && !isSelected
                            ? Theme.Colors.separator.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.sm)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor
        } else if isHovered {
            return Theme.Colors.separator.opacity(0.15)
        } else {
            return Color.clear
        }
    }

    /// 徽章计数（根据项目类型返回）
    private var badgeCount: Int? {
        // 可以根据需要连接实际数据
        // 例如：节点数量、未读日志数等
        nil
    }
}

/// 侧边栏底部按钮
struct SidebarFooterButton: View {
    let icon: String
    var tooltip: String = ""
    var isActive: Bool = false
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    isActive
                        ? Theme.Colors.accent
                        : (isHovered ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
                )
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? Theme.Colors.separator.opacity(0.2) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
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
            case .settings, .config:
                SettingsView()
            case .connections:
                PlaceholderView(title: "连接", icon: "point.3.connected.trianglepath.dotted")
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
