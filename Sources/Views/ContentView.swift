import SwiftUI

/// 导航目标枚举
enum NavigationItem: String, CaseIterable, Identifiable {
    case overview = "总览"
    case nodes = "节点"
    case rules = "规则"
    case logs = "日志"
    case settings = "设置"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "gauge.with.dots.needle.67percent"
        case .nodes: return "network"
        case .rules: return "list.bullet.rectangle"
        case .logs: return "doc.text"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .overview
    @EnvironmentObject var proxyManager: ProxyManager
    
    var body: some View {
        NavigationSplitView(sidebar: {
            Sidebar(selectedItem: $selectedItem)
        }, detail: {
            DetailView(selectedItem: selectedItem)
        })
        .navigationSplitViewStyle(.balanced)
    }
}

struct Sidebar: View {
    @Binding var selectedItem: NavigationItem
    @EnvironmentObject var proxyManager: ProxyManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo 区域
            HStack {
                Text("Phase")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            
            Divider()
            
            // 导航列表
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.icon)
                        .font(Theme.Typography.body)
                }
            }
            .listStyle(.sidebar)
            
            Spacer()
            
            // 底部状态栏
            VStack(spacing: Theme.Spacing.sm) {
                Divider()
                
                HStack {
                    Circle()
                        .fill(proxyManager.isRunning ? Theme.Colors.statusActive : Theme.Colors.statusInactive)
                        .frame(width: 8, height: 8)
                    
                    Text(proxyManager.isRunning ? "运行中" : "已停止")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
            }
        }
        .frame(minWidth: Theme.Layout.sidebarWidth)
    }
}

struct DetailView: View {
    let selectedItem: NavigationItem
    
    var body: some View {
        Group {
            switch selectedItem {
            case .overview:
                OverviewView()
            case .nodes:
                NodesView()
            case .rules:
                RulesView()
            case .logs:
                LogsView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 占位视图 - 用于未实现的页面
struct PlaceholderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text(title)
                .font(Theme.Typography.title1)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("此功能正在开发中")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProxyManager.shared)
        .frame(width: 900, height: 600)
}
