import SwiftUI

/// 规则管理页面
struct RulesView: View {
    @State private var ruleGroups: [RuleGroup] = []
    @State private var selectedGroupId: UUID?
    @State private var searchText = ""
    @State private var hoveredRuleId: UUID?

    private var selectedGroup: RuleGroup? {
        ruleGroups.first { $0.id == selectedGroupId }
    }

    private var totalRulesCount: Int {
        ruleGroups.reduce(0) { $0 + $1.rules.count }
    }

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
            // 标题栏
            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("规则组")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)

                    Spacer()
                }

                // 统计信息卡片
                HStack(spacing: Theme.Spacing.md) {
                    StatisticBadge(
                        icon: "folder.fill",
                        value: "\(ruleGroups.count)",
                        label: "组",
                        color: Theme.Colors.accent
                    )

                    StatisticBadge(
                        icon: "list.bullet",
                        value: "\(totalRulesCount)",
                        label: "规则",
                        color: Theme.Colors.secondaryText
                    )
                }
            }
            .padding(Theme.Spacing.lg)

            Divider()

            // 规则组列表
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(ruleGroups) { group in
                        RuleGroupCell(
                            group: group,
                            isSelected: selectedGroupId == group.id,
                            onSelect: {
                                withAnimation(Theme.Animation.fast) {
                                    selectedGroupId = group.id
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
                // 组信息
                HStack(spacing: Theme.Spacing.sm) {
                    Circle()
                        .fill(actionColor(for: group.action))
                        .frame(width: 10, height: 10)

                    Text(group.name)
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                }

                Spacer()

                // 搜索框
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.Colors.tertiaryText)
                        .font(.system(size: 13))

                    TextField("搜索规则", text: $searchText)
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
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.md)
                .frame(maxWidth: 300)

                // 规则数量标签
                HStack(spacing: 6) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                    Text("\(filteredRules(in: group).count)")
                        .font(Theme.Typography.callout)
                        .monospacedDigit()
                }
                .foregroundColor(Theme.Colors.secondaryText)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.md)
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
                            RuleCell(
                                rule: rule,
                                isHovered: hoveredRuleId == rule.id,
                                onHover: { isHovered in
                                    hoveredRuleId = isHovered ? rule.id : nil
                                }
                            )
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
    }

    private func actionColor(for action: RouteRule.RuleAction) -> Color {
        switch action {
        case .proxy: return Theme.Colors.accent
        case .direct: return Theme.Colors.statusActive
        case .reject: return Theme.Colors.statusError
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
            rule.name.localizedCaseInsensitiveContains(searchText)
                || rule.patterns.contains { $0.localizedCaseInsensitiveContains(searchText) }
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

        selectedGroupId = ruleGroups.first?.id
    }
}

// MARK: - Statistic Badge

private struct StatisticBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(value)
                .font(Theme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.primaryText)
                .monospacedDigit()

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Rule Group Cell

private struct RuleGroupCell: View {
    let group: RuleGroup
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.sm) {
                    // 动作指示器
                    ZStack {
                        Circle()
                            .fill(actionColor.opacity(0.15))
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(actionColor)
                            .frame(width: 8, height: 8)
                    }

                    Text(group.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.Colors.accent)
                            .font(.system(size: 14))
                    }
                }

                Divider()

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 10))
                        Text("\(group.rules.count)")
                            .monospacedDigit()
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)

                    Spacer()

                    Text(group.action.rawValue)
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(actionColor.opacity(0.15))
                        .foregroundColor(actionColor)
                        .cornerRadius(6)
                }
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(
                        isSelected
                            ? Theme.Colors.accent.opacity(0.08)
                            : (isHovered ? Theme.Colors.cardBackground : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? Theme.Colors.accent.opacity(0.1) : Color.clear, radius: 8, x: 0,
                y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
        }
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
    let isHovered: Bool
    let onHover: (Bool) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 规则头部
            HStack(spacing: Theme.Spacing.md) {
                // 图标
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(typeColor.opacity(0.1))
                        .frame(width: 32, height: 32)

                    Image(systemName: rule.type.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(typeColor)
                }

                // 规则名称
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)

                    HStack(spacing: Theme.Spacing.sm) {
                        // 规则类型
                        Text(rule.type.rawValue)
                            .font(Theme.Typography.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(typeColor.opacity(0.15))
                            .foregroundColor(typeColor)
                            .cornerRadius(6)

                        // 规则动作
                        HStack(spacing: 3) {
                            Image(systemName: actionIcon)
                                .font(.system(size: 9))
                            Text(rule.action.rawValue)
                        }
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(actionColor.opacity(0.15))
                        .foregroundColor(actionColor)
                        .cornerRadius(6)
                    }
                }

                Spacer()

                // 规则数量徽章
                VStack(spacing: 2) {
                    Text("\(rule.patterns.count)")
                        .font(Theme.Typography.bodyBold)
                        .foregroundColor(Theme.Colors.primaryText)
                        .monospacedDigit()
                    Text("项")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.background)
                .cornerRadius(Theme.CornerRadius.md)

                // 展开按钮
                if !rule.patterns.isEmpty {
                    Button(action: {
                        withAnimation(Theme.Animation.spring) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.md)

            // 规则模式列表（可展开）
            if isExpanded && !rule.patterns.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, Theme.Spacing.md)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(rule.patterns.enumerated()), id: \.offset) {
                                index, pattern in
                                HStack(spacing: Theme.Spacing.sm) {
                                    Text("\(index + 1).")
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.Colors.tertiaryText)
                                        .frame(width: 24, alignment: .trailing)
                                        .monospacedDigit()

                                    Text(pattern)
                                        .font(Theme.Typography.callout.monospaced())
                                        .foregroundColor(Theme.Colors.secondaryText)

                                    Spacer()
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, 6)
                                .background(
                                    index % 2 == 0
                                        ? Color.clear : Theme.Colors.background.opacity(0.5))
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .fill(isHovered ? Theme.Colors.background : Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(isHovered ? Theme.Colors.separator : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            onHover(hovering)
        }
    }

    private var typeColor: Color {
        switch rule.type {
        case .domain, .domainSuffix, .domainKeyword:
            return Color.blue
        case .ipCidr:
            return Color.purple
        case .geoip:
            return Color.orange
        case .geosite:
            return Color.green
        }
    }

    private var actionColor: Color {
        switch rule.action {
        case .proxy: return Theme.Colors.accent
        case .direct: return Theme.Colors.statusActive
        case .reject: return Theme.Colors.statusError
        }
    }

    private var actionIcon: String {
        switch rule.action {
        case .proxy: return "arrow.triangle.2.circlepath"
        case .direct: return "arrow.right"
        case .reject: return "xmark"
        }
    }
}

#Preview {
    RulesView()
        .frame(width: 900, height: 600)
}
