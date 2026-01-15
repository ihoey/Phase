import SwiftUI

/// 总览页面 - 显示代理状态、当前节点、流量统计
struct OverviewView: View {
    @EnvironmentObject var proxyManager: ProxyManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // 状态卡片
                statusCard
                
                // 流量统计卡片
                trafficCard
                
                // 当前节点卡片
                currentNodeCard
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: Theme.Layout.cardMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.background)
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        CardView {
            VStack(spacing: Theme.Spacing.lg) {
                HStack {
                    Text("代理状态")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Spacer()
                }
                
                // 大状态指示器
                HStack(spacing: Theme.Spacing.lg) {
                    Circle()
                        .fill(proxyManager.isRunning ? Theme.Colors.statusActive : Theme.Colors.statusInactive)
                        .frame(width: 20, height: 20)
                        .shadow(
                            color: proxyManager.isRunning ? Theme.Colors.statusActive.opacity(0.5) : .clear,
                            radius: 8
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(proxyManager.isRunning ? "代理已启用" : "代理已停止")
                            .font(Theme.Typography.title2)
                            .foregroundColor(Theme.Colors.primaryText)
                        
                        if proxyManager.isRunning, let node = proxyManager.selectedNode {
                            Text(node.name)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, Theme.Spacing.sm)
                
                Divider()
                
                // 开关按钮
                Button(action: {
                    withAnimation(Theme.Animation.standard) {
                        proxyManager.toggleProxy()
                    }
                }) {
                    HStack {
                        Image(systemName: proxyManager.isRunning ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 18))
                        Text(proxyManager.isRunning ? "停止代理" : "启动代理")
                            .font(Theme.Typography.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(Theme.CornerRadius.md)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Traffic Card
    
    private var trafficCard: some View {
        CardView {
            VStack(spacing: Theme.Spacing.lg) {
                HStack {
                    Text("流量统计")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Spacer()
                    
                    if proxyManager.isRunning {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Theme.Colors.statusActive)
                                .frame(width: 6, height: 6)
                            Text("实时")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                HStack(spacing: Theme.Spacing.xl) {
                    // 上传
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(Theme.Colors.accent)
                            Text("上传")
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Text(proxyManager.trafficStats.uploadFormatted)
                            .font(Theme.Typography.title2)
                            .foregroundColor(Theme.Colors.primaryText)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    // 下载
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(Theme.Colors.statusActive)
                            Text("下载")
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                        
                        Text(proxyManager.trafficStats.downloadFormatted)
                            .font(Theme.Typography.title2)
                            .foregroundColor(Theme.Colors.primaryText)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - Current Node Card
    
    private var currentNodeCard: some View {
        CardView {
            VStack(spacing: Theme.Spacing.lg) {
                HStack {
                    Text("当前节点")
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Spacer()
                }
                
                if let node = proxyManager.selectedNode {
                    VStack(spacing: Theme.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(node.name)
                                    .font(Theme.Typography.title2)
                                    .foregroundColor(Theme.Colors.primaryText)
                                
                                HStack(spacing: Theme.Spacing.sm) {
                                    Text(node.type.displayName)
                                        .font(Theme.Typography.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Theme.Colors.accent.opacity(0.1))
                                        .foregroundColor(Theme.Colors.accent)
                                        .cornerRadius(4)
                                    
                                    if let latency = node.latency {
                                        HStack(spacing: 4) {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                                .font(.system(size: 10))
                                            Text("\(latency)ms")
                                                .font(Theme.Typography.caption)
                                        }
                                        .foregroundColor(latencyColor(for: latency))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("\(node.server):\(node.port)")
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Spacer()
                        }
                    }
                } else {
                    HStack {
                        Text("未选择节点")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.tertiaryText)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func latencyColor(for latency: Int) -> Color {
        switch latency {
        case 0..<100: return Theme.Colors.statusActive
        case 100..<300: return Theme.Colors.statusWarning
        default: return Theme.Colors.statusError
        }
    }
}

#Preview {
    OverviewView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 800, height: 700)
}
