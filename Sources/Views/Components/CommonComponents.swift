import SwiftUI

/// 通用卡片容器
/// 提供一致的背景、圆角、阴影和内边距
struct CardView<Content: View>: View {
    let content: Content
    var padding: CGFloat = Theme.Spacing.lg
    
    init(padding: CGFloat = Theme.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

/// 状态指示器
/// 显示代理启用/禁用状态
struct StatusIndicator: View {
    let isActive: Bool
    let title: String
    var subtitle: String?
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 状态圆点
            Circle()
                .fill(isActive ? Theme.Colors.statusActive : Theme.Colors.statusInactive)
                .frame(width: 12, height: 12)
                .shadow(color: isActive ? Theme.Colors.statusActive.opacity(0.5) : .clear, radius: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.bodyBold)
                    .foregroundColor(Theme.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
        }
        .animation(Theme.Animation.fast, value: isActive)
    }
}

/// 节点单元格
/// 显示单个代理节点的信息
struct NodeCell: View {
    let name: String
    let type: String
    let latency: Int?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // 选中指示器
                Circle()
                    .fill(isSelected ? Theme.Colors.accent : Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Theme.Colors.accent : Theme.Colors.separator, lineWidth: 1.5)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text(type)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // 延迟显示
                if let latency = latency {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 10))
                        Text("\(latency)ms")
                            .font(Theme.Typography.caption)
                    }
                    .foregroundColor(latencyColor(for: latency))
                } else {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .fill(isSelected ? Theme.Colors.accent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func latencyColor(for latency: Int) -> Color {
        switch latency {
        case 0..<100: return Theme.Colors.statusActive
        case 100..<300: return Theme.Colors.statusWarning
        default: return Theme.Colors.statusError
        }
    }
}

/// 毛玻璃背景
/// macOS 原生毛玻璃效果
struct GlassBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview("StatusIndicator") {
    VStack(spacing: Theme.Spacing.lg) {
        StatusIndicator(isActive: true, title: "代理已启用", subtitle: "香港 01")
        StatusIndicator(isActive: false, title: "代理已禁用")
    }
    .padding()
}

#Preview("NodeCell") {
    VStack(spacing: Theme.Spacing.sm) {
        NodeCell(name: "香港 01", type: "Shadowsocks", latency: 45, isSelected: true) {}
        NodeCell(name: "新加坡 02", type: "VMess", latency: 156, isSelected: false) {}
        NodeCell(name: "美国 03", type: "Trojan", latency: 320, isSelected: false) {}
        NodeCell(name: "日本 04", type: "Hysteria2", latency: nil, isSelected: false) {}
    }
    .padding()
}

#Preview("CardView") {
    CardView {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("代理状态")
                .font(Theme.Typography.title3)
            
            StatusIndicator(isActive: true, title: "代理已启用", subtitle: "香港 01")
            
            Divider()
            
            HStack {
                Text("上传")
                    .foregroundColor(Theme.Colors.secondaryText)
                Spacer()
                Text("1.2 MB")
                    .font(Theme.Typography.bodyBold)
            }
            
            HStack {
                Text("下载")
                    .foregroundColor(Theme.Colors.secondaryText)
                Spacer()
                Text("5.8 MB")
                    .font(Theme.Typography.bodyBold)
            }
        }
    }
    .padding()
    .frame(width: 320)
}
