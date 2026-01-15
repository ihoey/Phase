import SwiftUI

/// 订阅管理页面
struct SubscriptionView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var subscriptions: [Subscription] = []
    @State private var showAddSheet = false
    @State private var updatingIds: Set<UUID> = []
    @State private var hoveredCardId: UUID?

    private let subscriptionService = SubscriptionService.shared

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbar

            Divider()

            // 订阅列表
            if subscriptions.isEmpty {
                emptyView
            } else {
                subscriptionList
            }
        }
        .background(Theme.Colors.background)
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet { subscription in
                withAnimation(Theme.Animation.spring) {
                    subscriptions.append(subscription)
                }
                saveSubscriptions()
            }
        }
        .onAppear {
            loadSubscriptions()
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text("订阅管理")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)

                if !subscriptions.isEmpty {
                    Text("\(subscriptions.count) 个订阅 · \(totalNodeCount) 个节点")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
            }

            Spacer()

            // 全部更新按钮
            if !subscriptions.isEmpty {
                Button(action: updateAllSubscriptions) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(updatingIds.isEmpty ? 0 : 360))
                            .animation(
                                updatingIds.isEmpty
                                    ? .default
                                    : .linear(duration: 1).repeatForever(autoreverses: false),
                                value: updatingIds.isEmpty)
                        Text("全部更新")
                    }
                    .font(Theme.Typography.callout)
                }
                .buttonStyle(.bordered)
                .disabled(!updatingIds.isEmpty)
            }

            // 添加按钮
            Button(action: { showAddSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("添加订阅")
                }
                .font(Theme.Typography.callout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.lg)
    }

    private var totalNodeCount: Int {
        subscriptions.reduce(0) { $0 + $1.nodeCount }
    }

    // MARK: - Subscription List

    private var subscriptionList: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.lg),
                    GridItem(.flexible(), spacing: Theme.Spacing.lg)
                ],
                spacing: Theme.Spacing.lg
            ) {
                ForEach(subscriptions) { subscription in
                    SubscriptionCard(
                        subscription: subscription,
                        isUpdating: updatingIds.contains(subscription.id),
                        isHovered: hoveredCardId == subscription.id,
                        onUpdate: {
                            updateSubscription(subscription)
                        },
                        onDelete: {
                            withAnimation(Theme.Animation.spring) {
                                deleteSubscription(subscription)
                            }
                        },
                        onHover: { isHovered in
                            hoveredCardId = isHovered ? subscription.id : nil
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "link.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("暂无订阅")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)

                Text("添加订阅链接，获取代理节点")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }

            Button(action: { showAddSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("添加第一个订阅")
                }
                .font(Theme.Typography.body)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func loadSubscriptions() {
        subscriptions = subscriptionService.loadSubscriptions()
    }

    private func saveSubscriptions() {
        subscriptionService.saveSubscriptions(subscriptions)
    }

    private func updateSubscription(_ subscription: Subscription) {
        guard !updatingIds.contains(subscription.id) else { return }

        updatingIds.insert(subscription.id)

        Task {
            do {
                let nodes = try await subscriptionService.updateSubscription(subscription)

                await MainActor.run {
                    // 更新订阅信息
                    if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
                        subscriptions[index].lastUpdate = Date()
                        subscriptions[index].nodeCount = nodes.count
                        saveSubscriptions()
                    }

                    // 将节点添加到 ProxyManager
                    proxyManager.addSubscriptionNodes(subscription.id, nodes: nodes)

                    updatingIds.remove(subscription.id)
                }
            } catch {
                await MainActor.run {
                    print("❌ 更新订阅失败: \(error.localizedDescription)")
                    updatingIds.remove(subscription.id)
                }
            }
        }
    }

    private func updateAllSubscriptions() {
        for subscription in subscriptions where subscription.isEnabled {
            updateSubscription(subscription)
        }
    }

    private func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveSubscriptions()

        // 从 ProxyManager 移除订阅节点
        proxyManager.removeSubscriptionNodes(subscription.id)
    }
}

// MARK: - Subscription Card

private struct SubscriptionCard: View {
    let subscription: Subscription
    let isUpdating: Bool
    let isHovered: Bool
    let onUpdate: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // 标题行
                HStack(alignment: .top, spacing: Theme.Spacing.md) {
                    // 图标
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
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
                            .frame(width: 48, height: 48)

                        Image(systemName: "link")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(subscription.name)
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primaryText)

                        Text(subscription.url)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // 状态标签
                    statusBadge
                }

                Divider()

                // 信息行
                HStack(spacing: Theme.Spacing.xl) {
                    InfoItem(
                        icon: "server.rack",
                        label: "节点数",
                        value: "\(subscription.nodeCount)",
                        color: .blue
                    )
                    InfoItem(
                        icon: "clock.arrow.circlepath",
                        label: "更新间隔",
                        value: "\(subscription.updateInterval)h",
                        color: .orange
                    )
                    InfoItem(
                        icon: "calendar.badge.clock",
                        label: "上次更新",
                        value: subscription.lastUpdateShort,
                        color: .purple
                    )
                }

                Divider()

                // 操作按钮
                HStack(spacing: Theme.Spacing.md) {
                    Button(action: onUpdate) {
                        HStack(spacing: 6) {
                            if isUpdating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            Text(isUpdating ? "更新中..." : "立即更新")
                                .font(Theme.Typography.callout)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isUpdating)

                    Button(action: { showDeleteConfirmation = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .medium))
                            Text("删除")
                                .font(Theme.Typography.callout)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                }
            }
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: isHovered ? Color.black.opacity(0.15) : Color.black.opacity(0.05),
            radius: isHovered ? 12 : 4,
            x: 0,
            y: isHovered ? 6 : 2
        )
        .animation(Theme.Animation.spring, value: isHovered)
        .onHover { hovering in
            onHover(hovering)
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除订阅「\(subscription.name)」吗？此操作无法撤销。")
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        if subscription.needsUpdate {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text("需要更新")
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.Colors.statusWarning.opacity(0.15))
            )
            .foregroundColor(Theme.Colors.statusWarning)
        } else if subscription.lastUpdate != nil {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                Text("已同步")
                    .font(Theme.Typography.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.Colors.statusActive.opacity(0.15))
            )
            .foregroundColor(Theme.Colors.statusActive)
        }
    }
}

private struct InfoItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
                Text(value)
                    .font(Theme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.primaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Add Subscription Sheet

private struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var updateInterval = 24
    @State private var isValidating = false
    @State private var urlError: String?

    let onAdd: (Subscription) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            header

            Divider()

            // 表单内容
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // 订阅名称
                    FormField(title: "订阅名称", icon: "tag.fill") {
                        TextField("例如：我的订阅", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 32)
                    }

                    // 订阅地址
                    FormField(title: "订阅地址", icon: "link", error: urlError) {
                        TextField("https://...", text: $url)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 32)
                            .onChange(of: url) {
                                urlError = nil
                            }
                    }

                    // 更新间隔
                    FormField(title: "更新间隔", icon: "clock.arrow.circlepath") {
                        Picker("", selection: $updateInterval) {
                            Text("6 小时").tag(6)
                            Text("12 小时").tag(12)
                            Text("24 小时").tag(24)
                            Text("48 小时").tag(48)
                            Text("72 小时").tag(72)
                        }
                        .pickerStyle(.segmented)
                    }

                    // 提示信息
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                        Text("订阅链接将定期自动更新，获取最新节点")
                            .font(Theme.Typography.caption)
                    }
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                            .fill(Theme.Colors.accent.opacity(0.05))
                    )
                }
                .padding(Theme.Spacing.xl)
            }

            Divider()

            // 按钮栏
            footer
        }
        .frame(width: 560, height: 480)
        .background(Theme.Colors.background)
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.accent.opacity(0.2), Theme.Colors.accent.opacity(0.1),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("添加订阅")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
                Text("添加订阅链接以获取代理节点")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
    }

    private var footer: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button("取消") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button(action: addSubscription) {
                HStack(spacing: 6) {
                    if isValidating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isValidating ? "验证中..." : "添加订阅")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(url.isEmpty || isValidating)
            .keyboardShortcut(.defaultAction)
        }
        .padding(Theme.Spacing.xl)
    }

    private func addSubscription() {
        guard !url.isEmpty else { return }

        // 验证 URL
        guard URL(string: url) != nil else {
            urlError = "无效的 URL 格式"
            return
        }

        let subscription = Subscription(
            name: name.isEmpty ? "新订阅" : name,
            url: url,
            updateInterval: updateInterval
        )
        onAdd(subscription)
        dismiss()
    }
}

// MARK: - Form Field

private struct FormField<Content: View>: View {
    let title: String
    let icon: String
    var error: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.accent)
                    .frame(width: 20)

                Text(title)
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(Theme.Colors.primaryText)
            }

            content()

            if let error = error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(Theme.Typography.caption)
                }
                .foregroundColor(Theme.Colors.statusError)
            }
        }
    }
}

#Preview {
    SubscriptionView()
        .frame(width: 800, height: 600)
}
