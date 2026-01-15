import SwiftUI

/// 节点页面 - 显示所有节点列表，支持延迟测试和切换
struct NodesView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var isTesting = false
    @State private var testingSubscriptionIds: Set<UUID> = []
    @State private var searchText = ""
    @State private var hoveredNodeId: UUID?
    @State private var sortOrder: SortOrder = .name
    @State private var collapsedGroups: Set<UUID> = []
    @State private var selectedTab: TabType = .subscription
    @State private var isTabHovered: TabType?

    private let subscriptionService = SubscriptionService.shared

    enum TabType: String, CaseIterable {
        case policy = "策略组"
        case subscription = "订阅组"

        var icon: String {
            switch self {
            case .policy: return "square.stack.3d.up"
            case .subscription: return "link.circle"
            }
        }

        var description: String {
            switch self {
            case .policy: return "按代理策略分组管理节点"
            case .subscription: return "按订阅来源分组管理节点"
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case name = "名称"
        case latency = "延迟"
        case type = "类型"

        var icon: String {
            switch self {
            case .name: return "textformat.abc"
            case .latency: return "gauge.medium"
            case .type: return "tag"
            }
        }
    }

    /// 按策略类型分组的节点
    private var policyGroupedNodes: [(name: String, icon: String, color: Color, nodes: [ProxyNode])]
    {
        var groups: [(name: String, icon: String, color: Color, nodes: [ProxyNode])] = []

        // 按协议类型分组
        let allNodes = proxyManager.nodes
        let typeGroups = Dictionary(grouping: allNodes) { $0.type }

        let typeConfigs: [(ProxyNode.ProxyType, String, String, Color)] = [
            (
                .shadowsocks, "Shadowsocks", "lock.shield.fill",
                Color(red: 0.4, green: 0.6, blue: 1.0)
            ),
            (.vmess, "VMess", "v.circle.fill", Color(red: 0.5, green: 0.8, blue: 0.6)),
            (.vless, "VLESS", "v.square.fill", Color(red: 0.6, green: 0.7, blue: 0.9)),
            (.trojan, "Trojan", "lock.circle.fill", Color(red: 1.0, green: 0.5, blue: 0.5)),
            (.hysteria2, "Hysteria2", "bolt.circle.fill", Color(red: 0.9, green: 0.6, blue: 0.3)),
            (.tuic, "TUIC", "t.circle.fill", Color(red: 0.8, green: 0.5, blue: 0.9)),
        ]

        for (type, name, icon, color) in typeConfigs {
            if let nodes = typeGroups[type], !nodes.isEmpty {
                let filteredNodes = filterAndSortNodes(nodes)
                if !filteredNodes.isEmpty {
                    groups.append((name: name, icon: icon, color: color, nodes: filteredNodes))
                }
            }
        }

        return groups
    }

    /// 获取订阅列表
    private var subscriptions: [Subscription] {
        subscriptionService.loadSubscriptions()
    }

    /// 按订阅分组的节点
    private var groupedNodes: [(subscription: Subscription?, nodes: [ProxyNode])] {
        var groups: [(subscription: Subscription?, nodes: [ProxyNode])] = []

        // 获取订阅节点
        for subscription in subscriptions {
            if let nodes = proxyManager.subscriptionNodes[subscription.id], !nodes.isEmpty {
                let filteredNodes = filterAndSortNodes(nodes)
                if !filteredNodes.isEmpty {
                    groups.append((subscription: subscription, nodes: filteredNodes))
                }
            }
        }

        // 获取没有订阅的节点（内置/手动添加的节点）
        let subscribedNodeIds = Set(
            proxyManager.subscriptionNodes.values.flatMap { $0.map { $0.id } })
        let manualNodes = proxyManager.nodes.filter { !subscribedNodeIds.contains($0.id) }
        if !manualNodes.isEmpty {
            let filteredNodes = filterAndSortNodes(manualNodes)
            if !filteredNodes.isEmpty {
                groups.append((subscription: nil, nodes: filteredNodes))
            }
        }

        return groups
    }

    private func filterAndSortNodes(_ nodes: [ProxyNode]) -> [ProxyNode] {
        var result = nodes

        // 搜索过滤
        if !searchText.isEmpty {
            result = result.filter { node in
                node.name.localizedCaseInsensitiveContains(searchText)
                    || node.type.displayName.localizedCaseInsensitiveContains(searchText)
                    || node.server.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 排序
        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .latency:
            result.sort { (a, b) in
                guard let latencyA = a.latency else { return false }
                guard let latencyB = b.latency else { return true }
                return latencyA < latencyB
            }
        case .type:
            result.sort { $0.type.displayName < $1.type.displayName }
        }

        return result
    }

    var filteredNodes: [ProxyNode] {
        filterAndSortNodes(proxyManager.nodes)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab 切换栏
            tabBar

            // 工具栏
            toolbar

            Divider()
                .opacity(0.5)

            // 节点列表
            if filteredNodes.isEmpty {
                emptyView
            } else {
                nodesList
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Theme.Colors.background,
                    Theme.Colors.background.opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(TabType.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    isHovered: isTabHovered == tab,
                    onSelect: {
                        withAnimation(Theme.Animation.spring) {
                            selectedTab = tab
                        }
                    },
                    onHover: { hovering in
                        withAnimation(Theme.Animation.fast) {
                            isTabHovered = hovering ? tab : nil
                        }
                    }
                )
            }

            Spacer()

            // 当前模式描述
            Text(selectedTab.description)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.tertiaryText)
                .padding(.trailing, Theme.Spacing.sm)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Theme.Colors.cardBackground.opacity(0.5)
        )
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .font(.system(size: 13))

                TextField("搜索节点名称、类型或服务器", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.body)

                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(Theme.Animation.fast) {
                            searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 9)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 0.5)
            )
            .frame(maxWidth: 350)

            // 排序选择器
            Menu {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button(action: {
                        withAnimation(Theme.Animation.fast) {
                            sortOrder = order
                        }
                    }) {
                        Label {
                            Text(order.rawValue)
                        } icon: {
                            Image(systemName: order.icon)
                            if sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: sortOrder.icon)
                        .font(.system(size: 13))
                    Text(sortOrder.rawValue)
                        .font(Theme.Typography.callout)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 9)
                .background(Theme.Colors.cardBackground)
                .foregroundColor(Theme.Colors.primaryText)
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .menuStyle(.borderlessButton)

            Spacer()

            // 统计信息
            HStack(spacing: 6) {
                Image(systemName: "network")
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .font(.system(size: 13))
                Text("\(filteredNodes.count) / \(proxyManager.nodes.count)")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .monospacedDigit()
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 9)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 0.5)
            )

            // 测试延迟按钮
            Button(action: testAllLatency) {
                HStack(spacing: 7) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.65)
                            .frame(width: 13, height: 13)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 13))
                    }
                    Text(isTesting ? "测试中..." : "测试延迟")
                        .font(Theme.Typography.callout)
                }
                .padding(.horizontal, Theme.Spacing.md + 2)
                .padding(.vertical, 9)
                .background(
                    isTesting ? Theme.Colors.accent.opacity(0.15) : Theme.Colors.accent.opacity(0.1)
                )
                .foregroundColor(Theme.Colors.accent)
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .disabled(isTesting)
            .opacity(isTesting ? 0.7 : 1.0)
            .animation(Theme.Animation.fast, value: isTesting)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.background)
    }

    // MARK: - Nodes List

    private var nodesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
                if selectedTab == .subscription {
                    // 订阅组视图
                    ForEach(groupedNodes, id: \.subscription?.id) { group in
                        NodeGroupView(
                            subscription: group.subscription,
                            nodes: group.nodes,
                            isCollapsed: group.subscription.map { collapsedGroups.contains($0.id) }
                                ?? false,
                            isTesting: group.subscription.map {
                                testingSubscriptionIds.contains($0.id)
                            } ?? isTesting,
                            selectedNodeId: proxyManager.selectedNode?.id,
                            hoveredNodeId: hoveredNodeId,
                            onToggleCollapse: {
                                if let id = group.subscription?.id {
                                    withAnimation(Theme.Animation.spring) {
                                        if collapsedGroups.contains(id) {
                                            collapsedGroups.remove(id)
                                        } else {
                                            collapsedGroups.insert(id)
                                        }
                                    }
                                }
                            },
                            onTestLatency: {
                                if let subscription = group.subscription {
                                    testSubscriptionLatency(subscription.id)
                                } else {
                                    testAllLatency()
                                }
                            },
                            onSelectNode: { node in
                                withAnimation(Theme.Animation.spring) {
                                    proxyManager.selectNode(node)
                                }
                            },
                            onHoverNode: { nodeId in
                                withAnimation(Theme.Animation.fast) {
                                    hoveredNodeId = nodeId
                                }
                            }
                        )
                    }
                } else {
                    // 策略组视图
                    ForEach(policyGroupedNodes, id: \.name) { group in
                        PolicyGroupView(
                            name: group.name,
                            icon: group.icon,
                            color: group.color,
                            nodes: group.nodes,
                            isCollapsed: collapsedGroups.contains(
                                UUID(uuidString: group.name) ?? UUID()),
                            isTesting: isTesting,
                            selectedNodeId: proxyManager.selectedNode?.id,
                            hoveredNodeId: hoveredNodeId,
                            onToggleCollapse: {
                                let id = UUID(uuidString: group.name) ?? UUID()
                                withAnimation(Theme.Animation.spring) {
                                    if collapsedGroups.contains(id) {
                                        collapsedGroups.remove(id)
                                    } else {
                                        collapsedGroups.insert(id)
                                    }
                                }
                            },
                            onTestLatency: testAllLatency,
                            onSelectNode: { node in
                                withAnimation(Theme.Animation.spring) {
                                    proxyManager.selectNode(node)
                                }
                            },
                            onHoverNode: { nodeId in
                                withAnimation(Theme.Animation.fast) {
                                    hoveredNodeId = nodeId
                                }
                            }
                        )
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .animation(Theme.Animation.standard, value: filteredNodes.map { $0.id })
        .animation(Theme.Animation.spring, value: selectedTab)
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.cardBackground)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                Image(systemName: searchText.isEmpty ? "network.slash" : "magnifyingglass")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(searchText.isEmpty ? "暂无节点" : "未找到匹配节点")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)

                if searchText.isEmpty {
                    Text("请在设置中添加订阅或手动添加节点")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.tertiaryText)
                } else {
                    Text("尝试使用不同的关键词搜索")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    // MARK: - Actions

    private func testAllLatency() {
        guard !isTesting else { return }

        isTesting = true

        Task {
            await proxyManager.testAllNodesLatency()
            await MainActor.run {
                isTesting = false
            }
        }
    }

    private func testSubscriptionLatency(_ subscriptionId: UUID) {
        guard !testingSubscriptionIds.contains(subscriptionId) else { return }

        testingSubscriptionIds.insert(subscriptionId)

        Task {
            await proxyManager.testSubscriptionNodesLatency(subscriptionId)
            testingSubscriptionIds.remove(subscriptionId)
        }
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: NodesView.TabType
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)

                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.accent,
                                        Theme.Colors.accent.opacity(0.85),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.cardBackground)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                    }
                }
            )
            .foregroundColor(
                isSelected
                    ? .white : (isHovered ? Theme.Colors.primaryText : Theme.Colors.secondaryText)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? Color.clear
                            : (isHovered ? Theme.Colors.separator.opacity(0.3) : Color.clear),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            onHover(hovering)
        }
    }
}

// MARK: - Policy Group View

private struct PolicyGroupView: View {
    let name: String
    let icon: String
    let color: Color
    let nodes: [ProxyNode]
    let isCollapsed: Bool
    let isTesting: Bool
    let selectedNodeId: UUID?
    let hoveredNodeId: UUID?
    let onToggleCollapse: () -> Void
    let onTestLatency: () -> Void
    let onSelectNode: (ProxyNode) -> Void
    let onHoverNode: (UUID?) -> Void

    @State private var isHovered = false

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 组标题栏
            policyGroupHeader

            // 节点网格
            if !isCollapsed {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(nodes) { node in
                        NodeCard(
                            node: node,
                            isSelected: selectedNodeId == node.id,
                            isHovered: hoveredNodeId == node.id,
                            onSelect: { onSelectNode(node) },
                            onHover: { isHovered in
                                onHoverNode(isHovered ? node.id : nil)
                            }
                        )
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: color.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var policyGroupHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 折叠按钮
            Button(action: onToggleCollapse) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            // 策略图标
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // 策略名称和节点数
            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                HStack(spacing: 4) {
                    Text("\(nodes.count) 个节点")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.tertiaryText)

                    if let avgLatency = averageLatency {
                        Text("•")
                            .foregroundColor(Theme.Colors.tertiaryText)
                        Text("平均 \(avgLatency)ms")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(color)
                    }
                }
            }

            Spacer()

            // 测速按钮
            Button(action: onTestLatency) {
                HStack(spacing: 6) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 11))
                    }
                    Text(isTesting ? "测试中" : "测速")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundColor(color)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isTesting)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .background(
            LinearGradient(
                colors: [color.opacity(0.03), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var averageLatency: Int? {
        let latencies = nodes.compactMap { $0.latency }
        guard !latencies.isEmpty else { return nil }
        return latencies.reduce(0, +) / latencies.count
    }
}

// MARK: - Node Group View

private struct NodeGroupView: View {
    let subscription: Subscription?
    let nodes: [ProxyNode]
    let isCollapsed: Bool
    let isTesting: Bool
    let selectedNodeId: UUID?
    let hoveredNodeId: UUID?
    let onToggleCollapse: () -> Void
    let onTestLatency: () -> Void
    let onSelectNode: (ProxyNode) -> Void
    let onHoverNode: (UUID?) -> Void

    @State private var isHovered = false

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 组标题栏
            groupHeader

            // 节点网格
            if !isCollapsed {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(nodes) { node in
                        NodeCard(
                            node: node,
                            isSelected: selectedNodeId == node.id,
                            isHovered: hoveredNodeId == node.id,
                            onSelect: { onSelectNode(node) },
                            onHover: { isHovered in
                                onHoverNode(isHovered ? node.id : nil)
                            }
                        )
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Theme.Colors.accent.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.Colors.accent.opacity(0.2),
                            Theme.Colors.separator.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var groupHeader: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 折叠按钮
            Button(action: onToggleCollapse) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Theme.Colors.background.opacity(0.5))
                    )
            }
            .buttonStyle(.plain)

            // 订阅图标
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent.opacity(0.8),
                                Theme.Colors.accent.opacity(0.5),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: subscription != nil ? "link.circle.fill" : "server.rack")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            // 订阅名称和节点数
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription?.name ?? "内置节点")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                HStack(spacing: 4) {
                    Text("\(nodes.count) 个节点")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.tertiaryText)

                    if let avgLatency = averageLatency {
                        Text("•")
                            .foregroundColor(Theme.Colors.tertiaryText)
                        Text("平均 \(avgLatency)ms")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.accent)
                    }
                }
            }

            Spacer()

            // 测速按钮
            Button(action: onTestLatency) {
                HStack(spacing: 6) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 11))
                    }
                    Text(isTesting ? "测试中" : "测速")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: [
                            Theme.Colors.accent.opacity(0.15),
                            Theme.Colors.accent.opacity(0.08),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundColor(Theme.Colors.accent)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isTesting)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm + 4)
        .background(
            LinearGradient(
                colors: [Theme.Colors.accent.opacity(0.02), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var averageLatency: Int? {
        let latencies = nodes.compactMap { $0.latency }
        guard !latencies.isEmpty else { return nil }
        return latencies.reduce(0, +) / latencies.count
    }
}

// MARK: - Node Card

private struct NodeCard: View {
    let node: ProxyNode
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm + 2) {
                // 顶部：选中状态和延迟
                HStack {
                    // 选中指示器
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Theme.Colors.accent, Theme.Colors.accent.opacity(0.7),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 10, height: 10)
                                .shadow(
                                    color: Theme.Colors.accent.opacity(0.5), radius: 3, x: 0, y: 1)
                        }

                        Circle()
                            .stroke(
                                isSelected
                                    ? Theme.Colors.accent : Theme.Colors.separator.opacity(0.5),
                                lineWidth: isSelected ? 2 : 1.5
                            )
                            .frame(width: 10, height: 10)
                    }

                    Spacer()

                    // 延迟
                    if let latency = node.latency {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            latencyColor(for: latency),
                                            latencyColor(for: latency).opacity(0.6),
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 4
                                    )
                                )
                                .frame(width: 7, height: 7)
                            Text("\(latency)ms")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(latencyColor(for: latency))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(latencyColor(for: latency).opacity(0.1))
                        .cornerRadius(6)
                    } else {
                        Text("--")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.separator.opacity(0.1))
                            .cornerRadius(6)
                    }
                }

                // 节点名称
                Text(node.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.primaryText)
                    .lineLimit(1)

                // 协议标签
                HStack(spacing: 5) {
                    Image(systemName: protocolIcon(for: node.type))
                        .font(.system(size: 10, weight: .medium))
                    Text(node.type.displayName)
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [
                            protocolColor(for: node.type).opacity(0.15),
                            protocolColor(for: node.type).opacity(0.08),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(protocolColor(for: node.type))
                .cornerRadius(6)
            }
            .padding(Theme.Spacing.md + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md + 2)
                    .fill(backgroundGradient)
                    .shadow(
                        color: isSelected
                            ? Theme.Colors.accent.opacity(0.15) : Color.black.opacity(0.03),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md + 2)
                    .stroke(borderGradient, lineWidth: borderWidth)
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            onHover(hovering)
        }
    }

    // MARK: - Computed Properties

    private var backgroundGradient: some ShapeStyle {
        if isSelected {
            return LinearGradient(
                colors: [
                    Theme.Colors.accent.opacity(0.1),
                    Theme.Colors.accent.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    Theme.Colors.cardBackground,
                    Theme.Colors.background.opacity(0.8),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Theme.Colors.background.opacity(0.6),
                    Theme.Colors.background.opacity(0.4),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var borderGradient: some ShapeStyle {
        if isSelected {
            return LinearGradient(
                colors: [Theme.Colors.accent.opacity(0.6), Theme.Colors.accent.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [Theme.Colors.separator.opacity(0.5), Theme.Colors.separator.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Theme.Colors.separator.opacity(0.2), Theme.Colors.separator.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var borderWidth: CGFloat {
        isSelected ? 1.5 : 1
    }

    // MARK: - Helper Functions

    private func latencyColor(for latency: Int) -> Color {
        switch latency {
        case 0..<80: return Theme.Colors.statusActive
        case 80..<150: return Color(red: 0.4, green: 0.8, blue: 0.6)
        case 150..<250: return Theme.Colors.statusWarning
        case 250..<400: return Color(red: 1.0, green: 0.6, blue: 0.3)
        default: return Theme.Colors.statusError
        }
    }

    private func protocolIcon(for type: ProxyNode.ProxyType) -> String {
        switch type {
        case .shadowsocks: return "lock.shield"
        case .vmess: return "v.circle"
        case .trojan: return "lock.circle"
        case .hysteria2: return "bolt.circle"
        case .vless: return "v.square"
        case .tuic: return "t.circle"
        }
    }

    private func protocolColor(for type: ProxyNode.ProxyType) -> Color {
        switch type {
        case .shadowsocks: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .vmess: return Color(red: 0.5, green: 0.8, blue: 0.6)
        case .trojan: return Color(red: 1.0, green: 0.5, blue: 0.5)
        case .hysteria2: return Color(red: 0.9, green: 0.6, blue: 0.3)
        case .vless: return Color(red: 0.6, green: 0.7, blue: 0.9)
        case .tuic: return Color(red: 0.8, green: 0.5, blue: 0.9)
        }
    }
}

#Preview {
    NodesView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 800, height: 600)
}
