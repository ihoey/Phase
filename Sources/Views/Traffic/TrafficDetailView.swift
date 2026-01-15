import Charts
import SwiftUI

/// 流量追踪详情页
struct TrafficDetailView: View {
  @EnvironmentObject var proxyManager: ProxyManager
  @StateObject private var tracker = TrafficTracker()
  @State private var selectedTab: TrafficTab = .process

  enum TrafficTab: String, CaseIterable {
    case process = "进程"
    case host = "主机"
    case interface = "接口"
    case proxy = "代理"
    case trend = "趋势"
    case rules = "规则"
  }

  var body: some View {
    VStack(spacing: 0) {
      // 顶部标签栏
      tabBar

      Divider()

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

  // MARK: - Tab Bar

  private var tabBar: some View {
    HStack(spacing: 0) {
      ForEach(TrafficTab.allCases, id: \.self) { tab in
        Button(action: {
          withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
          }
        }) {
          Text(tab.rawValue)
            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
            .foregroundColor(selectedTab == tab ? Theme.Colors.accent : Theme.Colors.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
              selectedTab == tab
                ? Theme.Colors.accent.opacity(0.1)
                : Color.clear
            )
        }
        .buttonStyle(.plain)
      }
      Spacer()
    }
    .padding(.horizontal, Theme.Spacing.md)
    .background(Theme.Colors.cardBackground)
  }

  // MARK: - Process View

  private var processView: some View {
    VStack(spacing: Theme.Spacing.md) {
      ForEach(tracker.topProcesses) { process in
        trafficItemCard(
          icon: "app.fill",
          title: process.name,
          subtitle: process.id,
          upload: process.uploadBytes,
          download: process.downloadBytes
        )
      }
    }
  }

  // MARK: - Host View

  private var hostView: some View {
    VStack(spacing: Theme.Spacing.md) {
      ForEach(tracker.topHosts) { host in
        trafficItemCard(
          icon: "network",
          title: host.host,
          subtitle: "\(host.connectionCount) 次连接",
          upload: host.uploadBytes,
          download: host.downloadBytes
        )
      }
    }
  }

  // MARK: - Interface View

  private var interfaceView: some View {
    VStack(spacing: Theme.Spacing.md) {
      ForEach(tracker.interfaces) { interface in
        trafficItemCard(
          icon: interfaceIcon(for: interface.type),
          title: interface.name,
          subtitle: interface.type.rawValue,
          upload: interface.uploadBytes,
          download: interface.downloadBytes
        )
      }
    }
  }

  // MARK: - Proxy View

  private var proxyView: some View {
    VStack(spacing: Theme.Spacing.md) {
      ForEach(tracker.proxies) { proxy in
        trafficItemCard(
          icon: proxyIcon(for: proxy.proxyType),
          title: proxy.proxyName,
          subtitle: "\(proxy.connectionCount) 次连接",
          upload: proxy.uploadBytes,
          download: proxy.downloadBytes
        )
      }
    }
  }

  // MARK: - Trend View

  private var trendView: some View {
    VStack(spacing: Theme.Spacing.lg) {
      // 统计卡片
      HStack(spacing: Theme.Spacing.md) {
        statCard(
          title: "7天总计", value: formatBytes(tracker.last7Days.reduce(0) { $0 + $1.totalBytes }))
        statCard(title: "日均流量", value: formatBytes(tracker.dailyAverage))
        statCard(title: "今日流量", value: formatBytes(tracker.last7Days.last?.totalBytes ?? 0))
      }

      // 7天趋势图
      CardView {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
          HStack {
            Image(systemName: "chart.bar.fill")
              .font(.system(size: 16))
              .foregroundColor(Theme.Colors.accent)
            Text("7天流量趋势")
              .font(.system(size: 14, weight: .semibold))
              .foregroundColor(Theme.Colors.primaryText)
            Spacer()
          }

          Chart(tracker.last7Days) { day in
            BarMark(
              x: .value("日期", day.dateFormatted),
              y: .value("流量", Double(day.totalBytes))
            )
            .foregroundStyle(Theme.Colors.accent.gradient)
          }
          .frame(height: 200)
          .chartYAxis {
            AxisMarks(position: .leading) { value in
              AxisValueLabel {
                if let bytes = value.as(Double.self) {
                  Text(formatBytes(Int64(bytes)))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.Colors.tertiaryText)
                }
              }
            }
          }
        }
      }

      // 上传下载对比
      CardView {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
          Text("上传/下载对比")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Theme.Colors.primaryText)

          Chart(tracker.last7Days) { day in
            BarMark(
              x: .value("日期", day.dateFormatted),
              y: .value("上传", Double(day.uploadBytes)),
              stacking: .standard
            )
            .foregroundStyle(Color.blue)

            BarMark(
              x: .value("日期", day.dateFormatted),
              y: .value("下载", Double(day.downloadBytes)),
              stacking: .standard
            )
            .foregroundStyle(Color.green)
          }
          .frame(height: 150)
        }
      }
    }
  }

  // MARK: - Rules View

  private var rulesView: some View {
    VStack(spacing: Theme.Spacing.md) {
      // 重置按钮
      HStack {
        Spacer()
        Button(action: {
          tracker.resetRuleStats()
        }) {
          HStack(spacing: 6) {
            Image(systemName: "arrow.counterclockwise")
              .font(.system(size: 12))
            Text("重置统计")
              .font(.system(size: 12, weight: .medium))
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.red.opacity(0.1))
          .foregroundColor(.red)
          .cornerRadius(6)
        }
        .buttonStyle(.plain)
      }

      // 规则列表
      ForEach(tracker.topRules) { rule in
        ruleCard(rule: rule)
      }
    }
  }

  // MARK: - Helper Views

  private func trafficItemCard(
    icon: String, title: String, subtitle: String, upload: Int64, download: Int64
  ) -> some View {
    CardView {
      HStack(spacing: Theme.Spacing.md) {
        // 图标
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(Theme.Colors.accent)
          .frame(width: 32)

        // 信息
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Theme.Colors.primaryText)
          Text(subtitle)
            .font(.system(size: 11))
            .foregroundColor(Theme.Colors.tertiaryText)
        }

        Spacer()

        // 流量数据
        VStack(alignment: .trailing, spacing: 4) {
          HStack(spacing: 4) {
            Image(systemName: "arrow.up")
              .font(.system(size: 9))
              .foregroundColor(Color.blue)
            Text(formatBytes(upload))
              .font(.system(size: 11))
              .foregroundColor(Theme.Colors.secondaryText)
          }
          HStack(spacing: 4) {
            Image(systemName: "arrow.down")
              .font(.system(size: 9))
              .foregroundColor(Color.green)
            Text(formatBytes(download))
              .font(.system(size: 11))
              .foregroundColor(Theme.Colors.secondaryText)
          }
        }
      }
    }
  }

  private func ruleCard(rule: RuleStats) -> some View {
    CardView {
      VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
        HStack {
          // 规则类型标签
          Text(rule.ruleType)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.Colors.accent.opacity(0.15))
            .foregroundColor(Theme.Colors.accent)
            .cornerRadius(3)

          // 动作标签
          Text(rule.action)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(actionColor(rule.action).opacity(0.15))
            .foregroundColor(actionColor(rule.action))
            .cornerRadius(3)

          Spacer()

          // 匹配次数
          Text(rule.matchCountFormatted)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Theme.Colors.primaryText)
        }

        // 规则名称
        Text(rule.ruleName)
          .font(.system(size: 12))
          .foregroundColor(Theme.Colors.secondaryText)
          .lineLimit(1)
      }
    }
  }

  private func statCard(title: String, value: String) -> some View {
    CardView {
      VStack(spacing: 8) {
        Text(title)
          .font(.system(size: 11))
          .foregroundColor(Theme.Colors.tertiaryText)
        Text(value)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Theme.Colors.primaryText)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, Theme.Spacing.sm)
    }
  }

  // MARK: - Helper Functions

  private func interfaceIcon(for type: InterfaceTraffic.InterfaceType) -> String {
    switch type {
    case .wifi: return "wifi"
    case .ethernet: return "cable.connector"
    case .vpn: return "lock.shield"
    case .cellular: return "antenna.radiowaves.left.and.right"
    case .other: return "network"
    }
  }

  private func proxyIcon(for type: String) -> String {
    switch type {
    case "proxy": return "arrow.triangle.swap"
    case "direct": return "arrow.forward"
    case "reject": return "xmark.circle"
    default: return "questionmark.circle"
    }
  }

  private func actionColor(_ action: String) -> Color {
    switch action {
    case "PROXY": return Color.blue
    case "DIRECT": return Color.green
    case "REJECT": return Color.red
    default: return Color.gray
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
}

#Preview {
  TrafficDetailView()
    .environmentObject(ProxyManager.shared)
    .frame(width: 900, height: 700)
}
