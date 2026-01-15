import Charts
import SwiftUI

/// 流量追踪详情页
struct TrafficDetailView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @StateObject private var tracker = TrafficTracker()
    @State private var selectedTab: TrafficTab = .process
    @State private var hoveredProcess: String? = nil

    enum TrafficTab: String, CaseIterable {
        case process = "进程"
        case host = "主机"
        case interface = "接口"
        case proxy = "代理"
        case trend = "趋势"
        case rules = "规则"

        var icon: String {
            switch self {
            case .process: return "app.fill"
            case .host: return "globe"
            case .interface: return "network"
            case .proxy: return "arrow.triangle.swap"
            case .trend: return "chart.xyaxis.line"
            case .rules: return "list.bullet.rectangle"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部统计概览
            trafficOverview
                .padding(Theme.Spacing.lg)

            // 标签栏
            tabBar
                .padding(.horizontal, Theme.Spacing.lg)

            // 内容区域
            ScrollView {
                Group {
                    switch selectedTab {
                    case .process:
                        processView
                    case .host:
                        hostView
                    case .interface:
                        interfaceView
                    case .proxy:
                        proxyView
                    case .trend:
                        trendView
                    case .rules:
                        rulesView
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
        .onAppear {
            tracker.addMockData()
        }
    }

    // MARK: - Traffic Overview

    private var trafficOverview: some View {
        HStack(spacing: Theme.Spacing.md) {
            TrafficOverviewStatCard(
                icon: "arrow.up.circle.fill",
                iconColor: Theme.Colors.chartUpload,
                title: "上传",
                value: formatSpeed(proxyManager.uploadSpeedHistory.last?.value ?? 0),
                trend: nil
            )

            TrafficOverviewStatCard(
                icon: "arrow.down.circle.fill",
                iconColor: Theme.Colors.chartDownload,
                title: "下载",
                value: formatSpeed(proxyManager.downloadSpeedHistory.last?.value ?? 0),
                trend: nil
            )

            TrafficOverviewStatCard(
                icon: "arrow.up.arrow.down.circle.fill",
                iconColor: Color.purple,
                title: "今日总计",
                value: formatBytes(
                    proxyManager.trafficStats.uploadBytes + proxyManager.trafficStats.downloadBytes),
                trend: nil
            )

            TrafficOverviewStatCard(
                icon: "link.circle.fill",
                iconColor: Color.orange,
                title: "活跃连接",
                value: "\(tracker.topProcesses.count)",
                trend: nil
            )
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(TrafficTab.allCases, id: \.self) { tab in
                TrafficTabButton(
                    title: tab.rawValue,
                    icon: tab.icon,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
            Spacer()
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }

    // MARK: - Process View

    private var processView: some View {
        VStack(spacing: Theme.Spacing.md) {
            // 实时速度图表
            RealTimeChartCard(tracker: tracker)

            // 进程列表
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(tracker.topProcesses) { process in
                    TrafficItemRow(
                        icon: "app.fill",
                        iconColor: colorForProcess(process.name),
                        title: process.name,
                        subtitle: process.id,
                        upload: process.uploadBytes,
                        download: process.downloadBytes,
                        isHovered: hoveredProcess == process.id
                    )
                    .onHover { isHovered in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            hoveredProcess = isHovered ? process.id : nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Host View

    private var hostView: some View {
        VStack(spacing: Theme.Spacing.md) {
            TopHostsCard(hosts: tracker.topHosts)

            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(tracker.topHosts) { host in
                    TrafficItemRow(
                        icon: "globe",
                        iconColor: .blue,
                        title: host.host,
                        subtitle: "\(host.connectionCount) 次连接",
                        upload: host.uploadBytes,
                        download: host.downloadBytes,
                        isHovered: false
                    )
                }
            }
        }
    }

    // MARK: - Interface View

    private var interfaceView: some View {
        VStack(spacing: Theme.Spacing.md) {
            InterfaceDistributionCard(interfaces: tracker.interfaces)

            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(tracker.interfaces) { interface in
                    InterfaceRow(interface: interface)
                }
            }
        }
    }

    // MARK: - Proxy View

    private var proxyView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProxyStatsCard(proxies: tracker.proxies)

            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(tracker.proxies) { proxy in
                    TrafficItemRow(
                        icon: proxyIcon(for: proxy.proxyType),
                        iconColor: proxyColor(for: proxy.proxyType),
                        title: proxy.proxyName,
                        subtitle: "\(proxy.connectionCount) 次连接 · \(proxy.proxyType.uppercased())",
                        upload: proxy.uploadBytes,
                        download: proxy.downloadBytes,
                        isHovered: false
                    )
                }
            }
        }
    }

    // MARK: - Trend View

    private var trendView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.md) {
                TrendStatCard(
                    title: "7天总计",
                    value: formatBytes(tracker.last7Days.reduce(0) { $0 + $1.totalBytes }),
                    icon: "calendar",
                    color: .blue
                )
                TrendStatCard(
                    title: "日均流量",
                    value: formatBytes(tracker.dailyAverage),
                    icon: "chart.bar",
                    color: .green
                )
                TrendStatCard(
                    title: "今日流量",
                    value: formatBytes(tracker.last7Days.last?.totalBytes ?? 0),
                    icon: "sun.max",
                    color: .orange
                )
            }

            WeeklyTrendChart(data: tracker.last7Days)
            UploadDownloadCompareChart(data: tracker.last7Days)
        }
    }

    // MARK: - Rules View

    private var rulesView: some View {
        VStack(spacing: Theme.Spacing.md) {
            RulesHeaderCard(rules: tracker.topRules) {
                tracker.resetRuleStats()
            }

            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(tracker.topRules) { rule in
                    RuleRow(rule: rule)
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func colorForProcess(_ name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan, .indigo]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }

    private func proxyIcon(for type: String) -> String {
        switch type {
        case "proxy": return "arrow.triangle.swap"
        case "direct": return "arrow.forward"
        case "reject": return "xmark.circle"
        default: return "questionmark.circle"
        }
    }

    private func proxyColor(for type: String) -> Color {
        switch type {
        case "proxy": return .blue
        case "direct": return .green
        case "reject": return .red
        default: return .gray
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0

        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }

    private func formatSpeed(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024.0
        let mb = kb / 1024.0

        if mb >= 1.0 {
            return String(format: "%.1f MB/s", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return String(format: "%.0f B/s", bytesPerSec)
        }
    }
}

// MARK: - Traffic Overview Stat Card

struct TrafficOverviewStatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let trend: String?

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.tertiaryText)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryText)

                    if let trend = trend {
                        Text(trend)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Traffic Tab Button

struct TrafficTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        isSelected
                            ? Theme.Colors.accent
                            : (isHovered ? Theme.Colors.separator.opacity(0.3) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Real Time Chart Card

struct RealTimeChartCard: View {
    @ObservedObject var tracker: TrafficTracker

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Label("实时速度", systemImage: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.Colors.chartDownload).frame(width: 8, height: 8)
                        Text("下载").font(.system(size: 11)).foregroundColor(
                            Theme.Colors.secondaryText)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Theme.Colors.chartUpload).frame(width: 8, height: 8)
                        Text("上传").font(.system(size: 11)).foregroundColor(
                            Theme.Colors.secondaryText)
                    }
                }
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.Colors.chartDownload.opacity(0.1),
                            Theme.Colors.chartUpload.opacity(0.1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 100)
                .overlay(
                    Text("实时流量图表")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.tertiaryText)
                )
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Traffic Item Row

struct TrafficItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let upload: Int64
    let download: Int64
    let isHovered: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .lineLimit(1)
            }

            Spacer()

            TrafficProgressBar(upload: upload, download: download)
                .frame(width: 80)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.Colors.chartUpload)
                    Text(formatBytes(upload))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.Colors.chartDownload)
                    Text(formatBytes(download))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Theme.Colors.separator.opacity(0.1) : Theme.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isHovered ? Theme.Colors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0

        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.0f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
}

// MARK: - Traffic Progress Bar

struct TrafficProgressBar: View {
    let upload: Int64
    let download: Int64

    var body: some View {
        let total = max(upload + download, 1)
        let uploadRatio = CGFloat(upload) / CGFloat(total)
        let downloadRatio = CGFloat(download) / CGFloat(total)

        GeometryReader { geo in
            HStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.chartUpload)
                    .frame(width: geo.size.width * uploadRatio * 0.95)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.Colors.chartDownload)
                    .frame(width: geo.size.width * downloadRatio * 0.95)
            }
        }
        .frame(height: 4)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.Colors.separator.opacity(0.3))
        )
    }
}

// MARK: - Top Hosts Card

struct TopHostsCard: View {
    let hosts: [HostTraffic]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("热门主机", systemImage: "flame.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryText)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(hosts.prefix(4)) { host in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }

                        Text(shortHostName(host.host))
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                            .lineLimit(1)

                        Text("\(host.connectionCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.Colors.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }

    private func shortHostName(_ host: String) -> String {
        let components = host.split(separator: ".")
        if components.count >= 2 {
            return String(components[components.count - 2])
        }
        return host
    }
}

// MARK: - Interface Distribution Card

struct InterfaceDistributionCard: View {
    let interfaces: [InterfaceTraffic]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("接口流量分布", systemImage: "chart.pie.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryText)

            HStack(spacing: Theme.Spacing.lg) {
                ForEach(interfaces) { interface in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .stroke(interfaceColor(interface.type).opacity(0.3), lineWidth: 4)
                                .frame(width: 50, height: 50)

                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    interfaceColor(interface.type),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))

                            Image(systemName: interfaceIcon(interface.type))
                                .font(.system(size: 16))
                                .foregroundColor(interfaceColor(interface.type))
                        }

                        Text(interface.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.Colors.primaryText)

                        Text(interface.type.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }

    private func interfaceIcon(_ type: InterfaceTraffic.InterfaceType) -> String {
        switch type {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .vpn: return "lock.shield"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .other: return "network"
        }
    }

    private func interfaceColor(_ type: InterfaceTraffic.InterfaceType) -> Color {
        switch type {
        case .wifi: return .blue
        case .ethernet: return .green
        case .vpn: return .purple
        case .cellular: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Interface Row

struct InterfaceRow: View {
    let interface: InterfaceTraffic

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(interfaceColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: interfaceIcon)
                    .font(.system(size: 16))
                    .foregroundColor(interfaceColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(interface.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryText)

                Text(interface.type.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("活跃")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.green.opacity(0.1)))

            VStack(alignment: .trailing, spacing: 2) {
                Text("↑ \(formatBytes(interface.uploadBytes))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.Colors.chartUpload)
                Text("↓ \(formatBytes(interface.downloadBytes))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.Colors.chartDownload)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }

    private var interfaceIcon: String {
        switch interface.type {
        case .wifi: return "wifi"
        case .ethernet: return "cable.connector"
        case .vpn: return "lock.shield"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .other: return "network"
        }
    }

    private var interfaceColor: Color {
        switch interface.type {
        case .wifi: return .blue
        case .ethernet: return .green
        case .vpn: return .purple
        case .cellular: return .orange
        case .other: return .gray
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        if mb >= 1.0 {
            return String(format: "%.1f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.0f KB", kb)
        }
        return "\(bytes) B"
    }
}

// MARK: - Proxy Stats Card

struct ProxyStatsCard: View {
    let proxies: [ProxyTraffic]

    private var totalUpload: Int64 { proxies.reduce(0) { $0 + $1.uploadBytes } }
    private var totalDownload: Int64 { proxies.reduce(0) { $0 + $1.downloadBytes } }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("代理流量统计", systemImage: "arrow.triangle.swap")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.Colors.primaryText)

            HStack(spacing: Theme.Spacing.lg) {
                ForEach(["proxy", "direct", "reject"], id: \.self) { type in
                    let count = proxies.filter { $0.proxyType == type }.count
                    VStack(spacing: 6) {
                        Text("\(count)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(proxyColor(for: type))

                        Text(proxyLabel(for: type))
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }

                Divider().frame(height: 40)

                VStack(spacing: 6) {
                    Text(formatBytes(totalUpload + totalDownload))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryText)

                    Text("总流量")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }

    private func proxyColor(for type: String) -> Color {
        switch type {
        case "proxy": return .blue
        case "direct": return .green
        case "reject": return .red
        default: return .gray
        }
    }

    private func proxyLabel(for type: String) -> String {
        switch type {
        case "proxy": return "代理"
        case "direct": return "直连"
        case "reject": return "拒绝"
        default: return type
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        let gb = mb / 1024.0
        if gb >= 1.0 { return String(format: "%.1f GB", gb) }
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Trend Stat Card

struct TrendStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.primaryText)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Weekly Trend Chart

struct WeeklyTrendChart: View {
    let data: [DailyTraffic]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Label("7天流量趋势", systemImage: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()

                Text("单位: MB")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }

            Chart(data) { day in
                BarMark(
                    x: .value("日期", day.dateFormatted),
                    y: .value("流量", Double(day.totalBytes) / 1024.0 / 1024.0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let mb = value.as(Double.self) {
                            Text(String(format: "%.0f", mb))
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.tertiaryText)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Theme.Colors.separator.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Upload Download Compare Chart

struct UploadDownloadCompareChart: View {
    let data: [DailyTraffic]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Label("上传/下载对比", systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.chartUpload)
                            .frame(width: 12, height: 8)
                        Text("上传")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.chartDownload)
                            .frame(width: 12, height: 8)
                        Text("下载")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }

            Chart(data) { day in
                BarMark(
                    x: .value("日期", day.dateFormatted),
                    y: .value("上传", Double(day.uploadBytes) / 1024.0 / 1024.0)
                )
                .foregroundStyle(Theme.Colors.chartUpload)
                .cornerRadius(3)
                .position(by: .value("Type", "upload"))

                BarMark(
                    x: .value("日期", day.dateFormatted),
                    y: .value("下载", Double(day.downloadBytes) / 1024.0 / 1024.0)
                )
                .foregroundStyle(Theme.Colors.chartDownload)
                .cornerRadius(3)
                .position(by: .value("Type", "download"))
            }
            .frame(height: 140)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Theme.Colors.separator.opacity(0.5))
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Rules Header Card

struct RulesHeaderCard: View {
    let rules: [RuleStats]
    let onReset: () -> Void

    private var totalMatches: Int { rules.reduce(0) { $0 + $1.matchCount } }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("规则匹配统计")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.primaryText)

                Text("共 \(rules.count) 条规则，\(totalMatches) 次匹配")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            Button(action: onReset) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                    Text("重置")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    let rule: RuleStats

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack {
                Text("\(rule.matchCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.primaryText)
                Text("次")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(rule.ruleName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primaryText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(rule.ruleType)
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.accent.opacity(0.15))
                        .foregroundColor(Theme.Colors.accent)
                        .cornerRadius(3)

                    Text(rule.action)
                        .font(.system(size: 9, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(actionColor.opacity(0.15))
                        .foregroundColor(actionColor)
                        .cornerRadius(3)
                }
            }

            Spacer()

            TrafficCircularProgressView(
                progress: min(Double(rule.matchCount) / 100.0, 1.0), color: actionColor
            )
            .frame(width: 32, height: 32)
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.Colors.cardBackground)
        )
    }

    private var actionColor: Color {
        switch rule.action {
        case "PROXY": return .blue
        case "DIRECT": return .green
        case "REJECT": return .red
        default: return .gray
        }
    }
}

// MARK: - Circular Progress View

struct TrafficCircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    TrafficDetailView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 900, height: 700)
}
