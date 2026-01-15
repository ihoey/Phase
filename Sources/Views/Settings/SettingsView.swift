import SwiftUI

/// 设置页面
struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoUpdate") private var autoUpdate = true
    @AppStorage("httpPort") private var httpPort = 7890
    @AppStorage("socksPort") private var socksPort = 7890
    @AppStorage("logLevel") private var logLevel = "info"
    @AppStorage("dnsServer") private var dnsServer = "223.5.5.5"
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // 通用设置
                generalSettings
                
                // 代理设置
                proxySettings
                
                // 高级设置
                advancedSettings
                
                // 关于
                aboutSection
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: Theme.Layout.cardMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background)
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        SettingsSection(title: "通用") {
            SettingsRow(
                icon: "power",
                title: "开机启动",
                subtitle: "登录时自动启动 Phase"
            ) {
                Toggle("", isOn: $launchAtLogin)
                    .labelsHidden()
            }
            
            Divider()
            
            SettingsRow(
                icon: "arrow.down.circle",
                title: "自动更新",
                subtitle: "自动检查并下载更新"
            ) {
                Toggle("", isOn: $autoUpdate)
                    .labelsHidden()
            }
        }
    }
    
    // MARK: - Proxy Settings
    
    private var proxySettings: some View {
        SettingsSection(title: "代理") {
            SettingsRow(
                icon: "network",
                title: "HTTP 端口",
                subtitle: "本地 HTTP 代理监听端口"
            ) {
                TextField("", value: $httpPort, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
            }
            
            Divider()
            
            SettingsRow(
                icon: "network",
                title: "SOCKS5 端口",
                subtitle: "本地 SOCKS5 代理监听端口"
            ) {
                TextField("", value: $socksPort, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
            }
            
            Divider()
            
            SettingsRow(
                icon: "folder",
                title: "配置目录",
                subtitle: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Phase").path ?? "Unknown"
            ) {
                Button("打开") {
                    openConfigDirectory()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Advanced Settings
    
    private var advancedSettings: some View {
        SettingsSection(title: "高级") {
            SettingsRow(
                icon: "doc.text",
                title: "日志级别",
                subtitle: "调整日志详细程度"
            ) {
                Picker("", selection: $logLevel) {
                    Text("TRACE").tag("trace")
                    Text("DEBUG").tag("debug")
                    Text("INFO").tag("info")
                    Text("WARN").tag("warn")
                    Text("ERROR").tag("error")
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            
            Divider()
            
            SettingsRow(
                icon: "server.rack",
                title: "DNS 服务器",
                subtitle: "自定义 DNS 服务器地址"
            ) {
                TextField("", text: $dnsServer)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 150)
                    .multilineTextAlignment(.trailing)
            }
            
            Divider()
            
            SettingsRow(
                icon: "trash",
                title: "清除缓存",
                subtitle: "删除所有缓存数据"
            ) {
                Button("清除") {
                    clearCache()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        CardView {
            VStack(spacing: Theme.Spacing.lg) {
                // Logo 和名称
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "network")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.Colors.accent)
                    
                    Text("Phase")
                        .font(Theme.Typography.title1)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text("版本 0.1.0")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Divider()
                
                // 信息行
                VStack(spacing: Theme.Spacing.md) {
                    AboutRow(label: "内核", value: "sing-box")
                    AboutRow(label: "许可证", value: "MIT License")
                    AboutRow(label: "构建日期", value: "2026-01-15")
                }
                
                Divider()
                
                // 链接
                HStack(spacing: Theme.Spacing.lg) {
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                            Text("GitHub")
                        }
                        .font(Theme.Typography.callout)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                            Text("文档")
                        }
                        .font(Theme.Typography.callout)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.bubble")
                            Text("反馈")
                        }
                        .font(Theme.Typography.callout)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func openConfigDirectory() {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("Phase") else { return }
        NSWorkspace.shared.open(url)
    }
    
    private func clearCache() {
        // TODO: 实现清除缓存逻辑
        print("清除缓存")
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.primaryText)
            
            CardView(padding: 0) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

// MARK: - Settings Row

private struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: Content
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 32)
            
            // 标题和副标题
            VStack(alignment: .leading, spacing: 4) {
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
        .padding(Theme.Spacing.lg)
    }
}

// MARK: - About Row

private struct AboutRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.primaryText)
        }
    }
}

#Preview {
    SettingsView()
        .frame(width: 800, height: 700)
}
