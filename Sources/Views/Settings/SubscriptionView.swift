import SwiftUI

/// 订阅管理页面
struct SubscriptionView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var subscriptions: [Subscription] = []
    @State private var showAddSheet = false
    @State private var updatingIds: Set<UUID> = []

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
                subscriptions.append(subscription)
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
            Text("订阅管理")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.primaryText)

            Spacer()

            // 全部更新按钮
            if !subscriptions.isEmpty {
                Button(action: updateAllSubscriptions) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
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
                    Image(systemName: "plus")
                    Text("添加订阅")
                }
                .font(Theme.Typography.callout)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Subscription List

    private var subscriptionList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(subscriptions) { subscription in
                    SubscriptionCard(
                        subscription: subscription,
                        isUpdating: updatingIds.contains(subscription.id),
                        onUpdate: {
                            updateSubscription(subscription)
                        },
                        onDelete: {
                            deleteSubscription(subscription)
                        }
                    )
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "link.circle")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)

            Text("暂无订阅")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)

            Text("点击右上角添加订阅")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.tertiaryText)
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
    let onUpdate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // 标题行
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscription.name)
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primaryText)

                        Text(subscription.url)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.tertiaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    // 状态标签
                    if subscription.needsUpdate {
                        Text("需要更新")
                            .font(Theme.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.statusWarning.opacity(0.1))
                            .foregroundColor(Theme.Colors.statusWarning)
                            .cornerRadius(4)
                    }
                }

                Divider()

                // 信息行
                HStack(spacing: Theme.Spacing.xl) {
                    InfoItem(label: "节点数", value: "\(subscription.nodeCount)")
                    InfoItem(label: "更新间隔", value: "\(subscription.updateInterval) 小时")
                    InfoItem(label: "上次更新", value: subscription.lastUpdateFormatted)
                }

                Divider()

                // 操作按钮
                HStack(spacing: Theme.Spacing.md) {
                    Button(action: onUpdate) {
                        HStack(spacing: 4) {
                            if isUpdating {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isUpdating ? "更新中..." : "更新")
                        }
                        .font(Theme.Typography.callout)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isUpdating)

                    Spacer()

                    Button(action: onDelete) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("删除")
                        }
                        .font(Theme.Typography.callout)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
    }
}

private struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
            Text(value)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.primaryText)
        }
    }
}

// MARK: - Add Subscription Sheet

private struct AddSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var url = ""
    @State private var updateInterval = 24

    let onAdd: (Subscription) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // 标题
            HStack {
                Text("添加订阅")
                    .font(Theme.Typography.title2)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
            }

            // 表单
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("订阅名称")
                        .font(Theme.Typography.bodyBold)
                    TextField("例如：我的订阅", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("订阅地址")
                        .font(Theme.Typography.bodyBold)
                    TextField("https://...", text: $url)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("更新间隔（小时）")
                        .font(Theme.Typography.bodyBold)
                    Picker("", selection: $updateInterval) {
                        Text("6 小时").tag(6)
                        Text("12 小时").tag(12)
                        Text("24 小时").tag(24)
                        Text("48 小时").tag(48)
                        Text("72 小时").tag(72)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Spacer()

            // 按钮
            HStack(spacing: Theme.Spacing.md) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("添加") {
                    let subscription = Subscription(
                        name: name.isEmpty ? "新订阅" : name,
                        url: url,
                        updateInterval: updateInterval
                    )
                    onAdd(subscription)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.isEmpty)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SubscriptionView()
        .frame(width: 800, height: 600)
}
