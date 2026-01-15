import SwiftUI

/// 总览页面 - 显示代理状态、当前节点、流量统计
struct OverviewView: View {
    @EnvironmentObject var proxyManager: ProxyManager

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // 顶部状态栏
                topStatusBar
                
                // 主要内容区域
                HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                    // 左侧列
                    VStack(spacing: Theme.Spacing.lg) {
                        // 运行状态卡片
                        runningStatusCard
                        
                        // 流量统计卡片
                        trafficStatsCard
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 右侧列
                    VStack(spacing: Theme.Spacing.lg) {
                        // 网络状态卡片
                        networkStatusCard
                        
                        // 控制面板
                        controlPanelCard
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Theme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Top Status Bar
    
    private var topStatusBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 代理模式切换
            ForEach(ProxyMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(Theme.Animation.standard) {
                        proxyManager.switchMode(mode)
                    }
                }) {
                    Text(mode.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            proxyManager.proxyMode == mode
                                ? .white
                                : Theme.Colors.secondaryText
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            proxyManager.proxyMode == mode
                                ? Theme.Colors.accent
                                : Theme.Colors.cardBackground
                        )
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // 系统代理指示器
            HStack(spacing: 6) {
                Circle()
                    .fill(proxyManager.isSystemProxyEnabled ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                Text("系统代理")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(6)
        }
    }
    
    // MARK: - Running Status Card
    
    private var runningStatusCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.accent)
                    Text("运行状态")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                }
                
                HStack(spacing: Theme.Spacing.xl) {
                    // 状态
                    VStack(alignment: .leading, spacing: 4) {
                        Text("状态")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.tertiaryText)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(proxyManager.isRunning ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(proxyManager.isRunning ? "已连接" : "未连接")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.primaryText)
                        }
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    // 节点
                    VStack(alignment: .leading, spacing: 4) {
                        Text("节点")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.tertiaryText)
                        if let node = proxyManager.selectedNode {
                            HStack(spacing: 6) {
                                Text(node.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryText)
                                    .lineLimit(1)
                                if let latency = node.latency {
                                    Text("\(latency)ms")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(latencyColor(for: latency))
                                }
                            }
                        } else {
                            Text("未选择")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Theme.Colors.tertiaryText)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Traffic Stats Card
    
    private var trafficStatsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.accent)
                    Text("流量统计")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    if proxyManager.isRunning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("实时")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.Colors.tertiaryText)
                        }
                    }
                }
                
                VStack(spacing: Theme.Spacing.md) {
                    // 实时速率图表
                    if proxyManager.isRunning && !proxyManager.uploadSpeedHistory.isEmpty {
                        TrafficSpeedChart(
                            uploadData: proxyManager.uploadSpeedHistory,
                            downloadData: proxyManager.downloadSpeedHistory
                        )
                        .padding(.vertical, Theme.Spacing.sm)
                    } else {
                        // 占位图表
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.Colors.tertiaryText.opacity(0.3))
                            Text("启动代理后显示实时流量")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.Colors.tertiaryText)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Divider()
                    
                    // 流量分布图
                    if proxyManager.trafficStats.uploadBytes > 0 || proxyManager.trafficStats.downloadBytes > 0 {
                        TrafficDistributionChart(
                            upload: proxyManager.trafficStats.uploadBytes,
                            download: proxyManager.trafficStats.downloadBytes
                        )
                        .padding(.vertical, Theme.Spacing.sm)
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("总上传")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.tertiaryText)
                                Text("0 B")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("总下载")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.Colors.tertiaryText)
                                Text("0 B")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Network Status Card
    
    private var networkStatusCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "network")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.accent)
                    Text("网络状态")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                }
                
                VStack(spacing: Theme.Spacing.sm) {
                    // 系统代理
                    statusRow(
                        icon: "globe",
                        title: "系统代理",
                        value: proxyManager.isSystemProxyEnabled ? "已启用" : "未启用",
                        valueColor: proxyManager.isSystemProxyEnabled ? Color.green : Theme.Colors.tertiaryText
                    )
                    
                    // 本地监听
                    statusRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "本地监听",
                        value: "127.0.0.1:7890",
                        valueColor: Theme.Colors.secondaryText
                    )
                    
                    // 代理模式
                    statusRow(
                        icon: "arrow.triangle.branch",
                        title: "代理模式",
                        value: proxyManager.proxyMode.rawValue,
                        valueColor: Theme.Colors.accent
                    )
                }
            }
        }
    }
    
    // MARK: - Control Panel Card
    
    private var controlPanelCard: some View {
        CardView {
            VStack(spacing: Theme.Spacing.md) {
                // 当前节点信息
                if let node = proxyManager.selectedNode {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("当前节点")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.tertiaryText)
                        
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(node.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.Colors.primaryText)
                                
                                HStack(spacing: 6) {
                                    Text(node.type.displayName)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Theme.Colors.accent.opacity(0.15))
                                        .foregroundColor(Theme.Colors.accent)
                                        .cornerRadius(3)
                                    
                                    if let latency = node.latency {
                                        HStack(spacing: 2) {
                                            Circle()
                                                .fill(latencyColor(for: latency))
                                                .frame(width: 4, height: 4)
                                            Text("\(latency)ms")
                                                .font(.system(size: 10))
                                                .foregroundColor(Theme.Colors.tertiaryText)
                                        }
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Text("\(node.server):\(node.port)")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    .padding(.bottom, Theme.Spacing.sm)
                }
                
                Divider()
                
                // 控制按钮
                HStack(spacing: Theme.Spacing.sm) {
                    // 主按钮 - 启动/停止
                    Button(action: {
                        withAnimation(Theme.Animation.standard) {
                            proxyManager.toggleProxy()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: proxyManager.isRunning ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 16))
                            Text(proxyManager.isRunning ? "停止" : "启动")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(proxyManager.isRunning ? Color.red.opacity(0.9) : Theme.Colors.accent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    // 系统代理开关
                    Button(action: {
                        withAnimation(Theme.Animation.standard) {
                            proxyManager.toggleSystemProxy()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: proxyManager.isSystemProxyEnabled ? "network" : "network.slash")
                                .font(.system(size: 16))
                            Text(proxyManager.isSystemProxyEnabled ? "关闭" : "开启")
                                .font(.system(size: 10))
                        }
                        .frame(width: 70)
                        .padding(.vertical, 8)
                        .background(
                            proxyManager.isRunning
                                ? (proxyManager.isSystemProxyEnabled 
                                    ? Color.green.opacity(0.15)
                                    : Theme.Colors.cardBackground)
                                : Theme.Colors.cardBackground.opacity(0.5)
                        )
                        .foregroundColor(
                            proxyManager.isRunning
                                ? (proxyManager.isSystemProxyEnabled ? Color.green : Theme.Colors.secondaryText)
                                : Theme.Colors.tertiaryText
                        )
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    proxyManager.isSystemProxyEnabled ? Color.green.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!proxyManager.isRunning)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func statusRow(icon: String, title: String, value: String, valueColor: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.tertiaryText)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(Theme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valueColor)
        }
    }

    private func latencyColor(for latency: Int) -> Color {
        switch latency {
        case 0..<100: return Color.green
        case 100..<300: return Color.orange
        default: return Color.red
        }
    }
}

#Preview {
    OverviewView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 900, height: 700)
}
