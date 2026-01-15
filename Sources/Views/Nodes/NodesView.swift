import SwiftUI

/// 节点页面 - 显示所有节点列表，支持延迟测试和切换
struct NodesView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var isTesting = false
    @State private var searchText = ""
    
    var filteredNodes: [ProxyNode] {
        if searchText.isEmpty {
            return proxyManager.nodes
        }
        return proxyManager.nodes.filter { node in
            node.name.localizedCaseInsensitiveContains(searchText) ||
            node.type.displayName.localizedCaseInsensitiveContains(searchText)
        }
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
                
                TextField("搜索节点", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.body)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // 测试延迟按钮
            Button(action: testAllLatency) {
                HStack(spacing: 6) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text(isTesting ? "测试中..." : "测试延迟")
                        .font(Theme.Typography.callout)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.accent.opacity(0.1))
                .foregroundColor(Theme.Colors.accent)
                .cornerRadius(Theme.CornerRadius.md)
            }
            .buttonStyle(.plain)
            .disabled(isTesting)
            
            // 节点数量
            Text("\(filteredNodes.count) 个节点")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.lg)
    }
    
    // MARK: - Nodes List
    
    private var nodesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(filteredNodes) { node in
                    NodeRow(
                        node: node,
                        isSelected: proxyManager.selectedNode?.id == node.id,
                        onSelect: {
                            withAnimation(Theme.Animation.fast) {
                                proxyManager.selectNode(node)
                            }
                        }
                    )
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: searchText.isEmpty ? "network.slash" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text(searchText.isEmpty ? "暂无节点" : "未找到匹配节点")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)
            
            if searchText.isEmpty {
                Text("请在设置中添加订阅或手动添加节点")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.md) {
                // 选中指示器
                Circle()
                    .fill(isSelected ? Theme.Colors.accent : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Theme.Colors.accent : Theme.Colors.separator, lineWidth: 1.5)
                    )
                
                // 节点信息
                VStack(alignment: .leading, spacing: 6) {
                    Text(node.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    HStack(spacing: Theme.Spacing.sm) {
                        // 协议类型标签
                        Text(node.type.displayName)
                            .font(Theme.Typography.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.accent.opacity(0.1))
                            .foregroundColor(Theme.Colors.accent)
                            .cornerRadius(4)
                        
                        // 服务器地址
                        Text("\(node.server):\(node.port)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                }
                
                Spacer()
                
                // 延迟显示
                if let latency = node.latency {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(latencyColor(for: latency))
                            .frame(width: 6, height: 6)
                        
                        Text("\(latency)ms")
                            .font(Theme.Typography.callout)
                            .foregroundColor(latencyColor(for: latency))
                            .monospacedDigit()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(latencyColor(for: latency).opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.md)
                } else {
                    Text("未测试")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.tertiaryText)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.accent.opacity(0.05) : Theme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func latencyColor(for latency: Int) -> Color {
        switch latency {
        case 0..<100: return Theme.Colors.statusActive
        case 100..<300: return Theme.Colors.statusWarning
        default: return Theme.Colors.statusError
        }
    }
}

#Preview {
    NodesView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 800, height: 600)
}
