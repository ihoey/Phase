import Charts
import SwiftUI

/// 总览页面 - macOS 原生设计仪表板
struct OverviewView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    @State private var selectedPeriod: TrafficPeriod = .today
    @State private var hoveredCard: String?

    enum TrafficPeriod: String, CaseIterable {
        case today = "今日"
        case month = "本月"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top Row: Status, Mode, Node (Fixed Height)
                HStack(spacing: 16) {
                    mainStatusCard
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 16) {
                        modeControlCard
                            .frame(maxHeight: .infinity)

                        nodeInfoCard
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 170)  // Reduced from 220

                // Middle Row: Real-time Traffic (Fixed Height)
                realTimeTrafficCard
                    .frame(height: 190)  // Reduced from 240

                // Bottom Row: Details (Grid)
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                    ], spacing: 16
                ) {
                    trafficStatsCard
                        .frame(height: 150)  // Reduced from 180

                    activeConnectionsCard
                        .frame(height: 150)  // Reduced from 180

                    topApplicationsCard
                        .frame(height: 150)  // Reduced from 180
                }
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Top Row Cards

    private var mainStatusCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Animated Status Ring
                ZStack {
                    // Outer Ripple
                    Circle()
                        .strokeBorder(
                            proxyManager.isRunning
                                ? Color.green.opacity(0.3) : Color.gray.opacity(0.1),
                            lineWidth: 1
                        )
                        .frame(width: 70, height: 70)

                    // Middle Ring
                    Circle()
                        .fill(
                            proxyManager.isRunning
                                ? Color.green.opacity(0.1)
                                : Color.gray.opacity(0.05)
                        )
                        .frame(width: 56, height: 56)

                    // Core Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            proxyManager.toggleProxy()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    proxyManager.isRunning
                                        ? Color.green.gradient
                                        : Color.gray.opacity(0.2).gradient
                                )
                                .shadow(
                                    color: proxyManager.isRunning ? .green.opacity(0.4) : .clear,
                                    radius: 8, y: 4
                                )

                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(proxyManager.isRunning ? .white : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 48, height: 48)
                }
                .padding(.top, 8)

                VStack(spacing: 4) {
                    Text(proxyManager.isRunning ? "Protected" : "Disconnected")
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    if let startTime = proxyManager.startTime {
                        Text("\(formatDuration(Date().timeIntervalSince(startTime)))")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } else {
                        Text("Ready to connect")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
        }
    }

    private var modeControlCard: some View {
        GlassCard {
            HStack(spacing: 12) {
                // Mode Selector
                VStack(alignment: .leading, spacing: 10) {
                    Label("代理模式", systemImage: "arrow.triangle.branch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        ForEach(ProxyMode.allCases, id: \.self) { mode in
                            Button(action: {
                                withAnimation { proxyManager.switchMode(mode) }
                            }) {
                                Text(mode.rawValue.prefix(1))
                                    .font(.system(size: 12, weight: .semibold))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        proxyManager.proxyMode == mode
                                            ? Color.blue.gradient
                                            : Color.gray.opacity(0.1).gradient
                                    )
                                    .foregroundStyle(
                                        proxyManager.proxyMode == mode ? .white : .primary
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .help(mode.rawValue)
                        }
                    }
                }

                Spacer(minLength: 0)

                // System Proxy Toggle
                VStack(alignment: .trailing, spacing: 10) {
                    Label("系统代理", systemImage: "gearshape.2")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { proxyManager.isSystemProxyEnabled },
                            set: { _ in proxyManager.toggleSystemProxy() }
                        )
                    )
                    .toggleStyle(.switch)
                    .disabled(!proxyManager.isRunning)
                    .scaleEffect(0.7)
                    .frame(height: 20)
                }
            }
            .padding(16)
        }
    }

    private var nodeInfoCard: some View {
        GlassCard {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("当前节点", systemImage: "server.rack")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(proxyManager.selectedNode?.name ?? "未选择")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if let latency = proxyManager.selectedNode?.latency {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(latency)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(latencyColor(latency))

                        Text("ms")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Helper for Duration

    private func formatDuration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    } /* Lines 101-787 omitted */

    // MARK: - Proxy Control Card (Removed)

    // MARK: - Network Latency Card (Removed)

    // MARK: - Real-time Traffic Card

    private var realTimeTrafficCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label {
                        Text("实时流量")
                            .font(.system(size: 15, weight: .semibold))
                    } icon: {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 14))
                            .foregroundStyle(.purple)
                    }

                    Spacer()

                    if proxyManager.isRunning {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .opacity(
                                    Double(Int(Date().timeIntervalSince1970) % 2 == 0 ? 1.0 : 0.5)
                                )
                                .animation(.easeInOut(duration: 1.0).repeatForever(), value: Date())
                            Text("Realtime")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if proxyManager.isRunning && !proxyManager.uploadSpeedHistory.isEmpty {
                    Chart {
                        ForEach(Array(proxyManager.downloadSpeedHistory.enumerated()), id: \.offset)
                        { _, point in
                            AreaMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Speed", point.value / 1024)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.monotone)

                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Speed", point.value / 1024)
                            )
                            .foregroundStyle(Color.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.monotone)
                        }

                        ForEach(Array(proxyManager.uploadSpeedHistory.enumerated()), id: \.offset) {
                            _, point in
                            AreaMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Speed", point.value / 1024)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.01)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.monotone)

                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Speed", point.value / 1024)
                            )
                            .foregroundStyle(Color.green)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.monotone)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(Color.secondary.opacity(0.2))
                        }
                    }
                    .chartLegend(position: .top, alignment: .leading) {
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("上传")
                                    .font(.system(size: 11))
                                if let last = proxyManager.uploadSpeedHistory.last {
                                    Text(formatSpeed(last.value))
                                        .font(
                                            .system(
                                                size: 11, weight: .semibold, design: .monospaced))
                                }
                            }

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                Text("下载")
                                    .font(.system(size: 11))
                                if let last = proxyManager.downloadSpeedHistory.last {
                                    Text(formatSpeed(last.value))
                                        .font(
                                            .system(
                                                size: 11, weight: .semibold, design: .monospaced))
                                }
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    .frame(height: 180)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.system(size: 40))
                            .foregroundStyle(.tertiary)
                            .symbolEffect(.pulse.byLayer, options: .repeating, isActive: true)
                        Text("连接代理后显示实时流量")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Traffic Stats Card

    private var trafficStatsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("流量统计", systemImage: "chart.bar.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Menu {
                        ForEach(TrafficPeriod.allCases, id: \.self) { period in
                            Button(period.rawValue) { selectedPeriod = period }
                        }
                    } label: {
                        Text(selectedPeriod.rawValue)
                            .font(.system(size: 12))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 40)
                }

                Spacer()

                VStack(spacing: 12) {
                    StatRow(
                        icon: "arrow.up.circle.fill",
                        iconColor: .green,
                        label: "上传",
                        value: formatBytes(proxyManager.trafficStats.uploadBytes)
                    )

                    StatRow(
                        icon: "arrow.down.circle.fill",
                        iconColor: .blue,
                        label: "下载",
                        value: formatBytes(proxyManager.trafficStats.downloadBytes)
                    )

                    Divider()
                        .padding(.vertical, 2)

                    StatRow(
                        icon: "arrow.up.arrow.down.circle.fill",
                        iconColor: .purple,
                        label: "总计",
                        value: formatBytes(
                            proxyManager.trafficStats.uploadBytes
                                + proxyManager.trafficStats.downloadBytes
                        )
                    )
                }

                Spacer()
            }
            .padding(20)
        }
    }

    // MARK: - Active Connections Card

    private var activeConnectionsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("活动连接", systemImage: "link.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TCP 连接")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(proxyManager.isRunning ? "23" : "-")
                                .font(.system(size: 20, weight: .bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("UDP 会话")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(proxyManager.isRunning ? "8" : "-")
                                .font(.system(size: 20, weight: .bold))
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    ConnectionRow(
                        icon: "app.badge.fill",
                        iconColor: .purple,
                        label: "活跃进程",
                        value: proxyManager.isRunning ? "8" : "-"
                    )
                }

                Spacer()
            }
            .padding(20)
        }
    }

    // MARK: - Top Applications Card

    private var topApplicationsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("热门应用", systemImage: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if proxyManager.isRunning {
                    VStack(spacing: 12) {
                        AppTrafficRow(name: "Safari", traffic: "126 MB", percentage: 0.8)
                        AppTrafficRow(name: "Chrome", traffic: "89 MB", percentage: 0.6)
                        AppTrafficRow(name: "Telegram", traffic: "35 MB", percentage: 0.25)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 24))
                            .foregroundStyle(.tertiary)
                        Text("暂无数据")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                Spacer()
            }
            .padding(20)
        }
    }

    // MARK: - Helper Components

    private func iconForMode(_ mode: ProxyMode) -> String {
        switch mode {
        case .direct: return "arrow.forward"
        case .rule: return "list.bullet"
        case .global: return "globe"
        }
    }

    private func latencyColor(_ latency: Int) -> Color {
        switch latency {
        case 0..<50: return .green
        case 50..<150: return .yellow
        case 150..<300: return .orange
        default: return .red
        }
    }

    private func formatSpeed(_ bytes: Double) -> String {
        let kb = bytes / 1024
        if kb < 1024 {
            return String(format: "%.1f KB/s", kb)
        } else {
            return String(format: "%.2f MB/s", kb / 1024)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Supporting Views

struct LatencyRow: View {
    let label: String
    let value: Int
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.primary)

            Spacer()

            Text("\(value)ms")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(value < 50 ? .green : value < 150 ? .orange : .red)
        }
    }
}

struct StatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

struct ConnectionRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
}

struct AppTrafficRow: View {
    let name: String
    let traffic: String
    let percentage: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Text(traffic)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.gradient)
                        .frame(width: geometry.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    OverviewView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 1000, height: 800)
}
