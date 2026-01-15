import SwiftUI

/// 设置页面
struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoUpdate") private var autoUpdate = true
    @AppStorage("httpPort") private var httpPort = 7890
    @AppStorage("socksPort") private var socksPort = 7890
    @AppStorage("logLevel") private var logLevel = "info"
    @AppStorage("dnsServer") private var dnsServer = "223.5.5.5"

    @State private var isClearing = false
    @State private var showClearSuccess = false
    @State private var hoveredSection: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // 通用设置
                generalSettings
                    .transition(.move(edge: .leading).combined(with: .opacity))

                // 代理设置
                proxySettings
                    .transition(.move(edge: .leading).combined(with: .opacity))

                // 高级设置
                advancedSettings
                    .transition(.move(edge: .leading).combined(with: .opacity))

                // 关于
                aboutSection
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .padding(Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background)
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        SettingsSection(
            title: "通用",
            icon: "gearshape.fill",
            iconColor: .blue
        ) {
            SettingsRow(
                icon: "power",
                iconColor: .green,
                title: "开机启动",
                subtitle: "登录时自动启动 Phase"
            ) {
                SettingsToggle(isOn: $launchAtLogin)
            }

            SettingsDivider()

            SettingsRow(
                icon: "arrow.down.circle.fill",
                iconColor: .cyan,
                title: "自动更新",
                subtitle: "自动检查并下载更新"
            ) {
                SettingsToggle(isOn: $autoUpdate)
            }
        }
    }

    // MARK: - Proxy Settings

    private var proxySettings: some View {
        SettingsSection(
            title: "代理",
            icon: "network",
            iconColor: .purple
        ) {
            SettingsRow(
                icon: "globe",
                iconColor: .orange,
                title: "HTTP 端口",
                subtitle: "本地 HTTP 代理监听端口"
            ) {
                PortTextField(value: $httpPort)
            }

            SettingsDivider()

            SettingsRow(
                icon: "network.badge.shield.half.filled",
                iconColor: .pink,
                title: "SOCKS5 端口",
                subtitle: "本地 SOCKS5 代理监听端口"
            ) {
                PortTextField(value: $socksPort)
            }

            SettingsDivider()

            SettingsRow(
                icon: "folder.fill",
                iconColor: .yellow,
                title: "配置目录",
                subtitle: configPath
            ) {
                SettingsButton(title: "打开", icon: "folder.badge.gearshape") {
                    openConfigDirectory()
                }
            }
        }
    }

    private var configPath: String {
        FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first?.appendingPathComponent("Phase").path ?? "Unknown"
    }

    // MARK: - Advanced Settings

    private var advancedSettings: some View {
        SettingsSection(
            title: "高级",
            icon: "slider.horizontal.3",
            iconColor: .orange
        ) {
            SettingsRow(
                icon: "doc.text.fill",
                iconColor: .indigo,
                title: "日志级别",
                subtitle: "调整日志详细程度"
            ) {
                LogLevelPicker(selection: $logLevel)
            }

            SettingsDivider()

            SettingsRow(
                icon: "server.rack",
                iconColor: .teal,
                title: "DNS 服务器",
                subtitle: "自定义 DNS 服务器地址"
            ) {
                DNSTextField(text: $dnsServer)
            }

            SettingsDivider()

            SettingsRow(
                icon: "trash.fill",
                iconColor: .red,
                title: "清除缓存",
                subtitle: showClearSuccess ? "✓ 缓存已清除" : "删除所有缓存数据"
            ) {
                ClearCacheButton(
                    isClearing: $isClearing,
                    showSuccess: $showClearSuccess,
                    action: clearCache
                )
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                Text("关于")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
            }

            CardView(padding: 0) {
                VStack(spacing: 0) {
                    // App Logo 和信息
                    VStack(spacing: Theme.Spacing.md) {
                        // App Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.2),
                                            Color.purple.opacity(0.2),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)

                            Image(systemName: "network")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 5)

                        VStack(spacing: Theme.Spacing.xs) {
                            Text("Phase")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.primaryText)

                            HStack(spacing: Theme.Spacing.sm) {
                                VersionBadge(text: "v0.1.0", color: .blue)
                                VersionBadge(text: "Beta", color: .orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
                    .background(
                        LinearGradient(
                            colors: [
                                Theme.Colors.cardBackground,
                                Theme.Colors.cardBackground.opacity(0.8),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    SettingsDivider()

                    // 信息行
                    VStack(spacing: 0) {
                        AboutInfoRow(icon: "cpu", label: "内核", value: "sing-box", color: .purple)
                        SettingsDivider()
                        AboutInfoRow(
                            icon: "doc.text", label: "许可证", value: "MIT License", color: .green)
                        SettingsDivider()
                        AboutInfoRow(
                            icon: "calendar", label: "构建日期", value: "2026-01-15", color: .orange)
                    }

                    SettingsDivider()

                    // 链接按钮
                    HStack(spacing: Theme.Spacing.md) {
                        LinkButton(
                            icon: "link",
                            title: "GitHub",
                            color: .primary
                        ) {
                            if let url = URL(string: "https://github.com/ihoey/Phase") {
                                NSWorkspace.shared.open(url)
                            }
                        }

                        LinkButton(
                            icon: "book.fill",
                            title: "文档",
                            color: .blue
                        ) {
                            // TODO: 打开文档链接
                        }

                        LinkButton(
                            icon: "bubble.left.fill",
                            title: "反馈",
                            color: .green
                        ) {
                            // TODO: 打开反馈链接
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func openConfigDirectory() {
        guard
            let url = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first?.appendingPathComponent("Phase")
        else { return }
        NSWorkspace.shared.open(url)
    }

    private func clearCache() {
        isClearing = true

        // 模拟清除缓存操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isClearing = false
            showClearSuccess = true

            // 3秒后隐藏成功提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showClearSuccess = false
            }
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content

    @State private var isHovered = false

    init(
        title: String,
        icon: String,
        iconColor: Color = .blue,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Section Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor.gradient)

                Text(title)
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
            }

            CardView(padding: 0) {
                VStack(spacing: 0) {
                    content
                }
            }
            .scaleEffect(isHovered ? 1.005 : 1.0)
            .animation(Theme.Animation.fast, value: isHovered)
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let trailing: Content

    @State private var isHovered = false

    init(
        icon: String,
        iconColor: Color = .blue,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }

            // 标题和副标题
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(Theme.Colors.primaryText)

                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // 右侧控件
            trailing
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(isHovered ? Theme.Colors.cardBackground.opacity(0.5) : Color.clear)
        .animation(Theme.Animation.fast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Settings Divider

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 60)
    }
}

// MARK: - Settings Toggle

private struct SettingsToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("", isOn: $isOn)
            .toggleStyle(.switch)
            .labelsHidden()
            .tint(Theme.Colors.accent)
    }
}

// MARK: - Port TextField

private struct PortTextField: View {
    @Binding var value: Int
    @State private var isFocused = false

    var body: some View {
        TextField("", value: $value, format: .number)
            .textFieldStyle(.plain)
            .font(.system(.body, design: .monospaced))
            .multilineTextAlignment(.center)
            .frame(width: 80)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.Colors.separator, lineWidth: 1)
            )
    }
}

// MARK: - DNS TextField

private struct DNSTextField: View {
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .font(.system(.body, design: .monospaced))
            .multilineTextAlignment(.trailing)
            .frame(width: 140)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.Colors.separator, lineWidth: 1)
            )
    }
}

// MARK: - Log Level Picker

private struct LogLevelPicker: View {
    @Binding var selection: String

    private let levels = [
        ("trace", "TRACE", Color.gray),
        ("debug", "DEBUG", Color.blue),
        ("info", "INFO", Color.green),
        ("warn", "WARN", Color.orange),
        ("error", "ERROR", Color.red),
    ]

    var body: some View {
        Menu {
            ForEach(levels, id: \.0) { level in
                Button(action: { selection = level.0 }) {
                    HStack {
                        Circle()
                            .fill(level.2)
                            .frame(width: 8, height: 8)
                        Text(level.1)
                        if selection == level.0 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(colorForLevel(selection))
                    .frame(width: 8, height: 8)
                Text(selection.uppercased())
                    .font(.system(.body, design: .monospaced, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.Colors.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func colorForLevel(_ level: String) -> Color {
        switch level {
        case "trace": return .gray
        case "debug": return .blue
        case "info": return .green
        case "warn": return .orange
        case "error": return .red
        default: return .gray
        }
    }
}

// MARK: - Settings Button

private struct SettingsButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(.callout, weight: .medium))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Theme.Colors.accent.opacity(0.15) : Theme.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Theme.Colors.accent : Theme.Colors.separator, lineWidth: 1)
            )
            .foregroundColor(isHovered ? Theme.Colors.accent : Theme.Colors.primaryText)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Clear Cache Button

private struct ClearCacheButton: View {
    @Binding var isClearing: Bool
    @Binding var showSuccess: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isClearing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                } else if showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                }

                Text(isClearing ? "清除中..." : (showSuccess ? "已清除" : "清除"))
                    .font(.system(.callout, weight: .medium))
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        showSuccess
                            ? Color.green.opacity(0.15)
                            : (isHovered ? Color.red.opacity(0.15) : Theme.Colors.background)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        showSuccess
                            ? Color.green
                            : (isHovered ? Color.red : Theme.Colors.separator),
                        lineWidth: 1
                    )
            )
            .foregroundColor(
                showSuccess
                    ? .green
                    : (isHovered ? .red : Theme.Colors.primaryText)
            )
        }
        .buttonStyle(.plain)
        .disabled(isClearing)
        .animation(Theme.Animation.fast, value: isClearing)
        .animation(Theme.Animation.fast, value: showSuccess)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Version Badge

private struct VersionBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

// MARK: - About Info Row

private struct AboutInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)

            Text(label)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)

            Spacer()

            Text(value)
                .font(.system(.callout, weight: .medium))
                .foregroundColor(Theme.Colors.primaryText)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }
}

// MARK: - Link Button

private struct LinkButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(.callout, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? color.opacity(0.1) : Theme.Colors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? color.opacity(0.5) : Theme.Colors.separator, lineWidth: 1)
            )
            .foregroundColor(isHovered ? color : Theme.Colors.primaryText)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 800, height: 800)
}
