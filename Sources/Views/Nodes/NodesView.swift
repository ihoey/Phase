import SwiftUI

/// 节点页面 - 显示所有节点列表，支持延迟测试和切换
struct NodesView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var isTesting = false
    @State private var searchText = ""
    @State private var hoveredNodeId: UUID?
    @State private var sortOrder: SortOrder = .name

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

    var filteredNodes: [ProxyNode] {
        var nodes = proxyManager.nodes

        // 搜索过滤
        if !searchText.isEmpty {
            nodes = nodes.filter { node in
                node.name.localizedCaseInsensitiveContains(searchText)
                    || node.type.displayName.localizedCaseInsensitiveContains(searchText)
                    || node.server.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 排序
        switch sortOrder {
        case .name:
            nodes.sort { $0.name < $1.name }
        case .latency:
            nodes.sort { (a, b) in
                guard let latencyA = a.latency else { return false }
                guard let latencyB = b.latency else { return true }
                return latencyA < latencyB
            }
        case .type:
            nodes.sort { $0.type.displayName < $1.type.displayName }
        }

        return nodes
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbar

            Divider()

            // 节点列表
            if filteredNodes.isEmpty {
                emptyView
            } else {
                nodesList
            }
        }
        .background(Theme.Colors.background)
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
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(filteredNodes) { node in
                    NodeRow(
                        node: node,
                        isSelected: proxyManager.selectedNode?.id == node.id,
                        isHovered: hoveredNodeId == node.id,
                        onSelect: {
                            withAnimation(Theme.Animation.spring) {
                                proxyManager.selectNode(node)
                            }
                        },
                        onHover: { isHovered in
                            withAnimation(Theme.Animation.fast) {
                                hoveredNodeId = isHovered ? node.id : nil
                            }
                        }
                    )
                    .transition(.scale(scale: 0.98).combined(with: .opacity))
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .animation(Theme.Animation.standard, value: filteredNodes.map { $0.id })
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
}

// MARK: - Node Row

private struct NodeRow: View {
    let node: ProxyNode
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onHover: (Bool) -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.md) {
                // 选中指示器
                ZStack {
                    Circle()
                        .fill(isSelected ? Theme.Colors.accent : Color.clear)
                        .frame(width: 10, height: 10)

                    Circle()
                        .stroke(
                            isSelected ? Theme.Colors.accent : Theme.Colors.separator, lineWidth: 2
                        )
                        .frame(width: 10, height: 10)
                        .scaleEffect(isHovered && !isSelected ? 1.2 : 1.0)
                        .animation(Theme.Animation.spring, value: isHovered)
                }

                // 节点信息
                VStack(alignment: .leading, spacing: 7) {
                    Text(node.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)
                        .lineLimit(1)

                    HStack(spacing: Theme.Spacing.sm) {
                        // 协议类型标签
                        HStack(spacing: 4) {
                            Image(systemName: protocolIcon(for: node.type))
                                .font(.system(size: 9))
                            Text(node.type.displayName)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(protocolColor(for: node.type).opacity(0.12))
                        .foregroundColor(protocolColor(for: node.type))
                        .cornerRadius(5)

                        // 服务器地址
                        HStack(spacing: 3) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 9))
                            Text("\(node.server):\(node.port)")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Theme.Colors.tertiaryText)
                    }
                }

                Spacer()

                // 延迟显示
                if let latency = node.latency {
                    HStack(spacing: 7) {
                        // 信号强度图标
                        Image(systemName: signalIcon(for: latency))
                            .font(.system(size: 13))
                            .foregroundColor(latencyColor(for: latency))

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(latency)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(latencyColor(for: latency))
                                .monospacedDigit()

                            Text("ms")
                                .font(.system(size: 9))
                                .foregroundColor(latencyColor(for: latency).opacity(0.7))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(latencyColor(for: latency).opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(latencyColor(for: latency).opacity(0.2), lineWidth: 1)
                    )
                } else {
                    HStack(spacing: 5) {
                        Image(systemName: "minus")
                            .font(.system(size: 11))
                        Text("未测试")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 10)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .stroke(Theme.Colors.separator.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md + 2)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(backgroundGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .scaleEffect(isHovered && !isSelected ? 1.005 : 1.0)
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
                    Theme.Colors.accent.opacity(0.08),
                    Theme.Colors.accent.opacity(0.05),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    Theme.Colors.cardBackground,
                    Theme.Colors.cardBackground.opacity(0.95),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Theme.Colors.cardBackground, Theme.Colors.cardBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Theme.Colors.accent.opacity(0.4)
        } else if isHovered {
            return Theme.Colors.separator.opacity(0.5)
        } else {
            return Theme.Colors.separator.opacity(0.2)
        }
    }

    private var borderWidth: CGFloat {
        isSelected ? 1.5 : 0.5
    }

    private var shadowColor: Color {
        if isSelected {
            return Theme.Colors.accent.opacity(0.15)
        } else if isHovered {
            return Color.black.opacity(0.08)
        } else {
            return Color.black.opacity(0.04)
        }
    }

    private var shadowRadius: CGFloat {
        isHovered || isSelected ? 8 : 4
    }

    private var shadowY: CGFloat {
        isHovered || isSelected ? 4 : 2
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

    private func signalIcon(for latency: Int) -> String {
        switch latency {
        case 0..<80: return "wifi"
        case 80..<150: return "wifi"
        case 150..<250: return "wifi.exclamationmark"
        default: return "wifi.slash"
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
