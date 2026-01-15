import SwiftUI

/// 规则管理页面
struct RulesView: View {
    @State private var ruleGroups: [RuleGroup] = []
    @State private var selectedGroup: RuleGroup?
    @State private var searchText = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：规则组列表
            ruleGroupsList
            
            Divider()
            
            // 右侧：规则详情
            if let group = selectedGroup {
                ruleDetailsView(for: group)
            } else {
                emptySelectionView
            }
        }
        .background(Theme.Colors.background)
        .onAppear {
            loadMockRules()
        }
    }
    
    // MARK: - Rule Groups List
    
    private var ruleGroupsList: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Text("规则组")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            
            Divider()
            
            // 规则组列表
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(ruleGroups) { group in
                        RuleGroupCell(
                            group: group,
                            isSelected: selectedGroup?.id == group.id,
                            onSelect: {
                                withAnimation(Theme.Animation.fast) {
                                    selectedGroup = group
                                }
                            }
                        )
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .frame(width: 280)
        .background(Theme.Colors.sidebarBackground)
    }
    
    // MARK: - Rule Details
    
    private func ruleDetailsView(for group: RuleGroup) -> some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack(spacing: Theme.Spacing.md) {
                // 搜索框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.tertiaryText)
                    
                    TextField("搜索规则", text: $searchText)
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
                
                // 规则数量
                Text("\(filteredRules(in: group).count) 条规则")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.lg)
            
            Divider()
            
            // 规则列表
            if filteredRules(in: group).isEmpty {
                emptyRulesView
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.sm) {
                        ForEach(filteredRules(in: group)) { rule in
                            RuleCell(rule: rule)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
    }
    
    private var emptySelectionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text("选择规则组")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("从左侧选择一个规则组以查看详情")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyRulesView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text(searchText.isEmpty ? "暂无规则" : "未找到匹配规则")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    
    private func filteredRules(in group: RuleGroup) -> [RouteRule] {
        if searchText.isEmpty {
            return group.rules
        }
        return group.rules.filter { rule in
            rule.name.localizedCaseInsensitiveContains(searchText) ||
            rule.patterns.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func loadMockRules() {
        ruleGroups = [
            RuleGroup(
                name: "代理规则",
                action: .proxy,
                rules: [
                    RouteRule(
                        name: "国外常用服务",
                        type: .geosite,
                        action: .proxy,
                        patterns: ["google", "youtube", "facebook", "twitter"]
                    ),
                    RouteRule(
                        name: "GitHub",
                        type: .domain,
                        action: .proxy,
                        patterns: ["github.com", "githubusercontent.com"]
                    ),
                    RouteRule(
                        name: "OpenAI",
                        type: .domainSuffix,
                        action: .proxy,
                        patterns: ["openai.com", "chatgpt.com"]
                    ),
                ]
            ),
            RuleGroup(
                name: "直连规则",
                action: .direct,
                rules: [
                    RouteRule(
                        name: "中国网站",
                        type: .geosite,
                        action: .direct,
                        patterns: ["cn", "geolocation-cn"]
                    ),
                    RouteRule(
                        name: "中国 IP",
                        type: .geoip,
                        action: .direct,
                        patterns: ["cn", "private"]
                    ),
                    RouteRule(
                        name: "局域网",
                        type: .ipCidr,
                        action: .direct,
                        patterns: ["192.168.0.0/16", "10.0.0.0/8", "127.0.0.1/8"]
                    ),
                ]
            ),
            RuleGroup(
                name: "拒绝规则",
                action: .reject,
                rules: [
                    RouteRule(
                        name: "广告域名",
                        type: .domainKeyword,
                        action: .reject,
                        patterns: ["ad", "ads", "analytics", "tracking"]
                    ),
                    RouteRule(
                        name: "广告服务",
                        type: .geosite,
                        action: .reject,
                        patterns: ["category-ads-all"]
                    ),
                ]
            ),
        ]
        
        selectedGroup = ruleGroups.first
    }
}

// MARK: - Rule Group Cell

private struct RuleGroupCell: View {
    let group: RuleGroup
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.sm) {
                    // 动作标签
                    Circle()
                        .fill(actionColor)
                        .frame(width: 8, height: 8)
                    
                    Text(group.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Spacer()
                }
                
                HStack {
                    Text("\(group.rules.count) 条规则")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.tertiaryText)
                    
                    Spacer()
                    
                    Text(group.action.rawValue)
                        .font(Theme.Typography.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(actionColor.opacity(0.1))
                        .foregroundColor(actionColor)
                        .cornerRadius(4)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.accent.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var actionColor: Color {
        switch group.action {
        case .proxy: return Theme.Colors.accent
        case .direct: return Theme.Colors.statusActive
        case .reject: return Theme.Colors.statusError
        }
    }
}

// MARK: - Rule Cell

private struct RuleCell: View {
    let rule: RouteRule
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // 规则名称和类型
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: rule.type.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.accent)
                    
                    Text(rule.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)
                }
                
                Spacer()
                
                // 规则类型标签
                Text(rule.type.rawValue)
                    .font(Theme.Typography.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.Colors.accent.opacity(0.1))
                    .foregroundColor(Theme.Colors.accent)
                    .cornerRadius(4)
            }
            
            // 规则模式
            if !rule.patterns.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(rule.patterns.prefix(3), id: \.self) { pattern in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Theme.Colors.tertiaryText)
                                .frame(width: 4, height: 4)
                            
                            Text(pattern)
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    if rule.patterns.count > 3 {
                        Text("还有 \(rule.patterns.count - 3) 项...")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .padding(.leading, 10)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

#Preview {
    RulesView()
        .frame(width: 900, height: 600)
}
