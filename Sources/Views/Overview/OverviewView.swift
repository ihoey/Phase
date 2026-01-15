import Charts
import SwiftUI

/// 总览页面 - 现代化仪表板设计
struct OverviewView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var selectedTrafficPeriod: TrafficPeriod = .today
    @State private var selectedRankType: RankType = .policy
    @State private var animateChart = false

    enum TrafficPeriod: String, CaseIterable {
        case today = "今天"
        case month = "本月"
        case lastMonth = "上月"
    }

    enum RankType: String, CaseIterable {
        case policy = "策略"
        case process = "进程"
        case network = "网络接口"
        case host = "主机名"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 第一行：运行状态 + 网络状态
                HStack(spacing: 20) {
                    runningStatusCard
                    networkStatusCard
                }
                .frame(height: 180)

                // 第二行：实时流量 + 7天流量趋势
                HStack(spacing: 20) {
                    realTimeTrafficCard
                    weeklyTrafficCard
                }
                .frame(height: 200)

                // 第三行：流量汇总
                trafficSummaryCard
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - 运行状态卡片

    private var runningStatusCard: some View {
        ModernCard(icon: "desktopcomputer", title: "运行状态", iconColor: .blue) {
            VStack(spacing: 16) {
                // 主要状态指标
                HStack(spacing: 0) {
                    // 运行时长 - 翻牌器样式
                    UptimeDisplay(
                        isRunning: proxyManager.isRunning,
                        startTime: proxyManager.startTime
                    )

                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 12)

                    // 连接数
                    AnimatedMetric(
                        icon: "link",
                        label: "连接数",
                        value: proxyManager.isRunning ? 12 : 0,
                        suffix: "",
                        color: proxyManager.isRunning ? .blue : .secondary
                    )

                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 12)

                    // 内存使用 - 带进度条
                    MemoryUsageMetric(
                        usedMB: proxyManager.isRunning ? 48 : 0,
                        totalMB: 256
                    )
                }

                Divider()

                // 底部状态栏 - 胶囊徽章
                HStack(spacing: 12) {
                    PillBadge(
                        icon: "circle.fill",
                        label: "状态",
                        value: proxyManager.isRunning ? "已连接" : "已断开",
                        isActive: proxyManager.isRunning,
                        showPulse: proxyManager.isRunning
                    )

                    PillBadge(
                        icon: "cpu",
                        label: "内核",
                        value: "sing-box",
                        isActive: true
                    )

                    PillBadge(
                        icon: "apple.logo",
                        label: "系统",
                        value: "macOS 15.0",
                        isActive: true
                    )

                    PillBadge(
                        icon: "number",
                        label: "版本",
                        value: "1.0.0",
                        isActive: true
                    )
                }
            }
        }
    }

    // MARK: - 网络状态卡片

    private var networkStatusCard: some View {
        ModernCard(icon: "globe", title: "网络状态", iconColor: .green) {
            VStack(spacing: 16) {
                // 延迟指标
                HStack(spacing: 0) {
                    LatencyMetric(
                        icon: "globe.americas",
                        label: "互联网",
                        latency: proxyManager.isRunning ? 235 : nil
                    )

                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 12)

                    LatencyMetric(
                        icon: "server.rack",
                        label: "DNS",
                        latency: proxyManager.isRunning ? 754 : nil
                    )

                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text("路由")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Text("-")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // 网络信息
                HStack(spacing: 24) {
                    StatusBadge(
                        icon: "wifi",
                        label: "网络",
                        value: "Ethernet",
                        isActive: true
                    )

                    StatusBadge(
                        icon: "network",
                        label: "本地IP",
                        value: getLocalIP(),
                        isActive: true
                    )

                    StatusBadge(
                        icon: "globe.asia.australia",
                        label: "代理IP",
                        value: proxyManager.isRunning ? "Hidden" : "-",
                        isActive: proxyManager.isRunning
                    )
                }
            }
        }
    }

    // MARK: - 实时流量卡片

    private var realTimeTrafficCard: some View {
        ModernCard(icon: "chart.line.uptrend.xyaxis", title: "实时流量", iconColor: .purple) {
            VStack(alignment: .leading, spacing: 10) {
                // 速度显示 - 带动画
                HStack(spacing: 0) {
                    // 上传速度区域
                    SpeedMetricView(
                        icon: "arrow.up.circle.fill",
                        label: "上传",
                        speed: proxyManager.isRunning ? proxyManager.uploadSpeedHistory.last?.value ?? 0 : 0,
                        peakSpeed: proxyManager.uploadSpeedHistory.map { $0.value }.max() ?? 0,
                        color: Theme.Colors.chartUpload
                    )

                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, 16)

                    // 下载速度区域
                    SpeedMetricView(
                        icon: "arrow.down.circle.fill",
                        label: "下载",
                        speed: proxyManager.isRunning ? proxyManager.downloadSpeedHistory.last?.value ?? 0 : 0,
                        peakSpeed: proxyManager.downloadSpeedHistory.map { $0.value }.max() ?? 0,
                        color: Theme.Colors.chartDownload
                    )
                }

                // 实时折线图 - 带发光效果
                EnhancedSpeedChart(
                    uploadHistory: proxyManager.uploadSpeedHistory,
                    downloadHistory: proxyManager.downloadSpeedHistory,
                    isRunning: proxyManager.isRunning
                )
                .frame(height: 60)

                // 简洁的累计流量显示
                HStack(spacing: 16) {
                    TrafficBadge(
                        icon: "arrow.up",
                        label: "已上传",
                        bytes: proxyManager.trafficStats.uploadBytes,
                        color: Theme.Colors.chartUpload
                    )

                    TrafficBadge(
                        icon: "arrow.down",
                        label: "已下载",
                        bytes: proxyManager.trafficStats.downloadBytes,
                        color: Theme.Colors.chartDownload
                    )
                    
                    Spacer()
                    
                    // 总计
                    HStack(spacing: 4) {
                        Image(systemName: "sum")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(formatBytes(proxyManager.trafficStats.uploadBytes + proxyManager.trafficStats.downloadBytes))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    // MARK: - 7天流量趋势

    private var weeklyTrafficCard: some View {
        ModernCard(
            icon: "chart.bar.fill",
            title: "7 天流量趋势",
            iconColor: .orange,
            trailing: {
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        ) {
            HStack(alignment: .bottom, spacing: 0) {
                // 日均统计
                VStack(alignment: .leading, spacing: 4) {
                    Text("日均")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("41.6 MB")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                .frame(width: 90, alignment: .leading)

                // 柱状图
                WeeklyBarChart()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - 流量汇总卡片

    private var trafficSummaryCard: some View {
        ModernCard(
            icon: "clock.arrow.circlepath",
            title: "流量汇总",
            iconColor: .cyan,
            trailing: {
                Button(action: {}) {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        ) {
            HStack(spacing: 24) {
                // 左侧：时间段选择 + 环形图
                VStack(spacing: 16) {
                    // 时间段选择器
                    HStack(spacing: 0) {
                        ForEach(TrafficPeriod.allCases, id: \.self) { period in
                            Button(action: { selectedTrafficPeriod = period }) {
                                Text(period.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedTrafficPeriod == period
                                            ? Color.accentColor
                                            : Color.clear
                                    )
                                    .foregroundColor(
                                        selectedTrafficPeriod == period
                                            ? .white
                                            : .secondary
                                    )
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    HStack(spacing: 24) {
                        // 环形进度图
                        TrafficRingChart(
                            upload: proxyManager.trafficStats.uploadBytes,
                            download: proxyManager.trafficStats.downloadBytes
                        )
                        .frame(width: 140, height: 140)

                        // 流量统计
                        VStack(alignment: .leading, spacing: 12) {
                            TrafficStatRow(
                                icon: "arrow.up.circle.fill",
                                label: "上传",
                                value: formatBytes(proxyManager.trafficStats.uploadBytes),
                                color: Theme.Colors.chartUpload
                            )

                            TrafficStatRow(
                                icon: "arrow.down.circle.fill",
                                label: "下载",
                                value: formatBytes(proxyManager.trafficStats.downloadBytes),
                                color: Theme.Colors.chartDownload
                            )

                            Divider()

                            // 直接连接与策略的流量比例
                            TrafficRatioBar(
                                directBytes: Int64(
                                    Double(
                                        proxyManager.trafficStats.uploadBytes
                                            + proxyManager.trafficStats.downloadBytes) * 0.05),
                                proxyBytes: Int64(
                                    Double(
                                        proxyManager.trafficStats.uploadBytes
                                            + proxyManager.trafficStats.downloadBytes) * 0.95)
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 140)

                // 右侧：排行榜
                VStack(alignment: .leading, spacing: 12) {
                    // 排行榜标题和类型选择
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "list.number")
                                .font(.system(size: 12))
                            Text("排行榜")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.secondary)

                        Spacer()

                        // 类型选择器
                        HStack(spacing: 0) {
                            ForEach(RankType.allCases, id: \.self) { type in
                                Button(action: { selectedRankType = type }) {
                                    Text(type.rawValue)
                                        .font(.system(size: 11))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            selectedRankType == type
                                                ? Color.gray.opacity(0.2)
                                                : Color.clear
                                        )
                                        .foregroundColor(
                                            selectedRankType == type
                                                ? .primary
                                                : .secondary
                                        )
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if proxyManager.isRunning {
                        // 排行列表
                        VStack(spacing: 8) {
                            RankRow(rank: 1, name: "DIRECT", traffic: "12.5 MB")
                            RankRow(rank: 2, name: "Proxy", traffic: "8.2 MB")
                            RankRow(rank: 3, name: "Reject", traffic: "0 B")
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text("-")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helpers

    private var formattedUptime: String {
        guard let startTime = proxyManager.startTime else {
            return "00:00"
        }
        let interval = Date().timeIntervalSince(startTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    private func getLocalIP() -> String {
        // 简化显示
        return "192.168.x.x"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }

    private func formatSpeed(_ bytes: Double) -> String {
        let kb = bytes / 1024
        if kb < 1024 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return String(format: "%.2f MB/s", kb / 1024)
        }
    }
}

// MARK: - 现代卡片容器

struct ModernCard<Content: View, Trailing: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let trailing: () -> Trailing
    let content: () -> Content

    init(
        icon: String,
        title: String,
        iconColor: Color = .blue,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题栏
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                }

                Spacer()

                trailing()
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - 状态指标组件

struct StatusMetric: View {
    let icon: String
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LatencyMetric: View {
    let icon: String
    let label: String
    let latency: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                if let latency = latency {
                    Text("\(latency)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(latencyColor(latency))
                    Text("ms")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(latencyColor(latency).opacity(0.7))
                } else {
                    Text("-")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func latencyColor(_ latency: Int) -> Color {
        switch latency {
        case 0..<100: return Theme.Colors.statusActive
        case 100..<300: return Theme.Colors.statusWarning
        default: return Theme.Colors.statusError
        }
    }
}

struct StatusBadge: View {
    let icon: String
    let label: String
    let value: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(isActive ? Theme.Colors.statusActive : .secondary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 运行时长组件

struct UptimeDisplay: View {
    let isRunning: Bool
    let startTime: Date?
    @State private var currentTime = Date()

    // 每分钟更新一次，节省资源
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("运行时长")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 2) {
                // 根据运行时长决定显示格式
                if days > 0 {
                    // 超过1天: 显示 Xd HH:MM
                    Text("\(days)d")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.statusActive)
                    Text(" ")
                    FlipDigit(value: hours % 24 / 10)
                    FlipDigit(value: hours % 24 % 10)
                    Text(":")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.statusActive)
                    FlipDigit(value: minutes / 10)
                    FlipDigit(value: minutes % 10)
                } else {
                    // 不到1天: 显示 HH:MM
                    FlipDigit(value: hours / 10)
                    FlipDigit(value: hours % 10)
                    Text(":")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.statusActive)
                    FlipDigit(value: minutes / 10)
                    FlipDigit(value: minutes % 10)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            // 首次显示时立即更新
            currentTime = Date()
        }
    }

    private var totalSeconds: Int {
        guard isRunning, let start = startTime else { return 0 }
        return Int(currentTime.timeIntervalSince(start))
    }

    private var days: Int {
        totalSeconds / 86400
    }

    private var hours: Int {
        totalSeconds / 3600
    }

    private var minutes: Int {
        (totalSeconds % 3600) / 60
    }
}

// MARK: - 翻牌数字

struct FlipDigit: View {
    let value: Int

    var body: some View {
        Text("\(value)")
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(Theme.Colors.statusActive)
            .frame(width: 16)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
    }
}

// MARK: - 动画数字指标

struct AnimatedMetric: View {
    let icon: String
    let label: String
    let value: Int
    let suffix: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(color.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 内存使用指标

struct MemoryUsageMetric: View {
    let usedMB: Int
    let totalMB: Int

    private var progress: Double {
        guard totalMB > 0 else { return 0 }
        return Double(usedMB) / Double(totalMB)
    }

    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return Theme.Colors.statusActive
        case 0.5..<0.8: return Theme.Colors.statusWarning
        default: return Theme.Colors.statusError
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("内存")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(usedMB)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(progressColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: usedMB)
                Text("MB")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(progressColor.opacity(0.7))
            }

            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [progressColor.opacity(0.8), progressColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 胶囊徽章

struct PillBadge: View {
    let icon: String
    let label: String
    let value: String
    let isActive: Bool
    var showPulse: Bool = false

    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                if showPulse {
                    Circle()
                        .fill(Theme.Colors.statusActive.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(isPulsing ? 1.5 : 1.0)
                        .opacity(isPulsing ? 0 : 0.5)
                }

                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(isActive ? Theme.Colors.statusActive : .secondary)
            }
            .frame(width: 16, height: 16)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isActive ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(
                    isActive ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15),
                    lineWidth: 1)
        )
        .onAppear {
            if showPulse {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: showPulse) { _, newValue in
            if newValue {
                isPulsing = false
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - 速度显示组件

struct SpeedDisplay: View {
    let icon: String
    let label: String
    let speed: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)

            Text(formatSpeed(speed))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }

    private func formatSpeed(_ bytes: Double) -> String {
        let kb = bytes / 1024
        if kb < 1 {
            return "0.0 KB/s"
        } else if kb < 1024 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return String(format: "%.2f MB/s", kb / 1024)
        }
    }
}

// MARK: - 流量滑块

struct TrafficSlider: View {
    let icon: String
    let label: String
    let current: Int64
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    // 进度条
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(CGFloat(current) / 1024 / 1024 * 10, geometry.size.width))

                    // 滑块指示器
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                        .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
                        .offset(
                            x: min(CGFloat(current) / 1024 / 1024 * 10, geometry.size.width - 12))
                }
            }
            .frame(height: 8)

            Text(formatBytes(current))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 7天柱状图 (带Hover效果)

struct WeeklyBarChart: View {
    let data: [(day: String, value: Double)] = [
        ("周四", 25), ("周三", 38), ("周二", 42),
        ("周一", 291.5), ("周日", 48), ("周六", 35), ("周五", 45),
    ]
    @State private var hoveredIndex: Int? = nil

    var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    ZStack(alignment: .top) {
                        // 悬停提示
                        if hoveredIndex == index {
                            Text(String(format: "%.1f MB", item.value))
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                                .offset(y: -24)
                                .transition(.opacity.combined(with: .scale))
                        }

                        // 柱状图
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                hoveredIndex == index
                                    ? LinearGradient(
                                        colors: [Color.orange.opacity(0.8), Color.orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                            )
                            .frame(width: 22, height: max(8, CGFloat(item.value / maxValue) * 80))
                    }

                    Text(item.day)
                        .font(.system(size: 9))
                        .foregroundColor(hoveredIndex == index ? .orange : .secondary)
                }
                .onHover { isHovered in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredIndex = isHovered ? index : nil
                    }
                }
            }
        }
    }
}

// MARK: - 流量环形图

struct TrafficRingChart: View {
    let upload: Int64
    let download: Int64

    var total: Int64 { upload + download }

    var body: some View {
        ZStack {
            // 外环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)

            // 渐变环
            Circle()
                .trim(from: 0, to: total > 0 ? 0.75 : 0)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.cyan,
                            Color.blue,
                            Color.purple,
                            Color.pink,
                            Color.cyan,
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: total)

            // 中心文本
            VStack(spacing: 2) {
                Text("总计")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(formatBytes(total))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 速度指标视图

struct SpeedMetricView: View {
    let icon: String
    let label: String
    let speed: Double
    let peakSpeed: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 标签
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 峰值显示在右上角，始终占位
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.to.line")
                        .font(.system(size: 8))
                    Text(peakSpeed > 0 ? formatSpeed(peakSpeed) : "-")
                        .font(.system(size: 9))
                }
                .foregroundColor(.secondary.opacity(0.6))
            }
            
            // 速度值
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatSpeedValue(speed))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: speed)
                
                Text(formatSpeedUnit(speed))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatSpeedValue(_ bytes: Double) -> String {
        let kb = bytes / 1024
        if kb < 1 {
            return "0.0"
        } else if kb < 1024 {
            return String(format: "%.1f", kb)
        } else {
            return String(format: "%.2f", kb / 1024)
        }
    }
    
    private func formatSpeedUnit(_ bytes: Double) -> String {
        let kb = bytes / 1024
        return kb < 1024 ? "KB/s" : "MB/s"
    }
    
    private func formatSpeed(_ bytes: Double) -> String {
        let kb = bytes / 1024
        if kb < 1 {
            return "0 KB/s"
        } else if kb < 1024 {
            return String(format: "%.0f KB/s", kb)
        } else {
            return String(format: "%.1f MB/s", kb / 1024)
        }
    }
}

// MARK: - 增强速度折线图

struct EnhancedSpeedChart: View {
    let uploadHistory: [TrafficDataPoint]
    let downloadHistory: [TrafficDataPoint]
    let isRunning: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 网格背景
                ChartGridBackground(size: geometry.size)
                
                // 下载曲线
                GlowingSpeedCurve(
                    data: downloadHistory,
                    size: geometry.size,
                    color: Theme.Colors.chartDownload,
                    showCurrentPoint: isRunning
                )
                
                // 上传曲线
                GlowingSpeedCurve(
                    data: uploadHistory,
                    size: geometry.size,
                    color: Theme.Colors.chartUpload,
                    showCurrentPoint: isRunning
                )
            }
        }
    }
}

// MARK: - 图表网格背景

struct ChartGridBackground: View {
    let size: CGSize
    
    var body: some View {
        Canvas { context, size in
            let horizontalLines = 3
            let verticalLines = 6
            
            // 水平线
            for i in 0...horizontalLines {
                let y = size.height * CGFloat(i) / CGFloat(horizontalLines)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.gray.opacity(0.1)), lineWidth: 1)
            }
            
            // 垂直线
            for i in 0...verticalLines {
                let x = size.width * CGFloat(i) / CGFloat(verticalLines)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.gray.opacity(0.1)), lineWidth: 1)
            }
        }
    }
}

// MARK: - 发光速度曲线

struct GlowingSpeedCurve: View {
    let data: [TrafficDataPoint]
    let size: CGSize
    let color: Color
    var showCurrentPoint: Bool = true
    
    @State private var isAnimating = false
    
    var body: some View {
        let points = normalizedPoints
        
        ZStack {
            // 渐变填充区域
            Path { path in
                guard points.count > 1 else { return }
                path.move(to: CGPoint(x: points[0].x, y: size.height))
                path.addLine(to: points[0])
                
                for i in 1..<points.count {
                    let control1 = CGPoint(
                        x: points[i - 1].x + (points[i].x - points[i - 1].x) / 2,
                        y: points[i - 1].y
                    )
                    let control2 = CGPoint(
                        x: points[i - 1].x + (points[i].x - points[i - 1].x) / 2,
                        y: points[i].y
                    )
                    path.addCurve(to: points[i], control1: control1, control2: control2)
                }
                
                path.addLine(to: CGPoint(x: points.last!.x, y: size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.25), color.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // 发光效果 - 模糊层
            curvePath(points: points)
                .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .blur(radius: 4)
            
            // 主曲线
            curvePath(points: points)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.8), color],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            
            // 当前点高亮
            if showCurrentPoint, let lastPoint = points.last {
                ZStack {
                    // 脉冲效果
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(isAnimating ? 1.5 : 1)
                        .opacity(isAnimating ? 0 : 0.5)
                    
                    // 外圈
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 10, height: 10)
                    
                    // 内圈
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
                .position(lastPoint)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private func curvePath(points: [CGPoint]) -> Path {
        Path { path in
            guard points.count > 1 else { return }
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let control1 = CGPoint(
                    x: points[i - 1].x + (points[i].x - points[i - 1].x) / 2,
                    y: points[i - 1].y
                )
                let control2 = CGPoint(
                    x: points[i - 1].x + (points[i].x - points[i - 1].x) / 2,
                    y: points[i].y
                )
                path.addCurve(to: points[i], control1: control1, control2: control2)
            }
        }
    }
    
    private var normalizedPoints: [CGPoint] {
        guard !data.isEmpty else {
            return generateStaticWave()
        }
        
        let maxValue = max(data.map { $0.value }.max() ?? 1, 1024)
        let count = data.count
        
        return data.enumerated().map { index, point in
            let x = size.width * CGFloat(index) / CGFloat(max(count - 1, 1))
            let y = size.height - (size.height * CGFloat(point.value) / CGFloat(maxValue)) * 0.85
            return CGPoint(x: x, y: max(8, min(y, size.height - 8)))
        }
    }
    
    private func generateStaticWave() -> [CGPoint] {
        let pointCount = 20
        return (0..<pointCount).map { i in
            let x = size.width * CGFloat(i) / CGFloat(pointCount - 1)
            let wave = sin(Double(i) * 0.5) * 0.3 + 0.5
            let y = size.height * (1 - CGFloat(wave) * 0.2)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - 简洁流量徽章

struct TrafficBadge: View {
    let icon: String
    let label: String
    let bytes: Int64
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            // 带颜色的圆点
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            // 标签
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            // 数值
            Text(formatBytes(bytes))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 流量环形指示器（保留用于其他地方）

struct TrafficRingIndicator: View {
    let icon: String
    let label: String
    let bytes: Int64
    let color: Color
    
    // 假设最大值为 1GB 用于进度显示
    private let maxBytes: Int64 = 1024 * 1024 * 1024
    
    private var progress: Double {
        min(Double(bytes) / Double(maxBytes), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 环形进度
            ZStack {
                // 背景环
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 4)
                    .frame(width: 36, height: 36)
                
                // 进度环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.7), color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // 文字信息
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text(formatBytes(bytes))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 旧版组件保留用于兼容

struct RealTimeSpeedChart: View {
    let uploadHistory: [TrafficDataPoint]
    let downloadHistory: [TrafficDataPoint]

    var body: some View {
        EnhancedSpeedChart(
            uploadHistory: uploadHistory,
            downloadHistory: downloadHistory,
            isRunning: true
        )
    }
}

// MARK: - 流量比例进度条

struct TrafficRatioBar: View {
    let directBytes: Int64
    let proxyBytes: Int64

    var total: Int64 { directBytes + proxyBytes }
    var directRatio: CGFloat { total > 0 ? CGFloat(directBytes) / CGFloat(total) : 0 }
    var proxyRatio: CGFloat { total > 0 ? CGFloat(proxyBytes) / CGFloat(total) : 0 }

    var body: some View {
        VStack(spacing: 8) {
            // 标签和数值
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                    Text("直接连接")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatBytes(directBytes))
                        .font(.system(size: 11, weight: .medium))
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 6, height: 6)
                    Text("策略")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(formatBytes(proxyBytes))
                        .font(.system(size: 11, weight: .medium))
                }
            }

            // 进度条
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // 直接连接部分（蓝色）
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(geometry.size.width * directRatio, directBytes > 0 ? 20 : 0))

                    // 策略部分（紫色/粉色渐变）
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(geometry.size.width * proxyRatio, proxyBytes > 0 ? 20 : 0))
                }
            }
            .frame(height: 6)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 { return "0 KB" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 流量统计行

struct TrafficStatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
        }
    }
}

// MARK: - 排行行

struct RankRow: View {
    let rank: Int
    let name: String
    let traffic: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(name)
                .font(.system(size: 12))
                .lineLimit(1)

            Spacer()

            Text(traffic)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - GlassCard (保留兼容)

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

#Preview {
    OverviewView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 900, height: 700)
}
