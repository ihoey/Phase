import SwiftUI

/// Phase 设计系统主题
/// 现代深色设计，灵感来自专业代理工具
enum Theme {
    
    // MARK: - Colors
    
    enum Colors {
        /// 主色调 - 系统蓝（用于强调和操作按钮）
        static let accent = Color.accentColor
        
        /// 状态色 - 启用（翠绿色）
        static let statusActive = Color(red: 0.2, green: 0.85, blue: 0.55)
        
        /// 状态色 - 禁用（灰色）
        static let statusInactive = Color.gray
        
        /// 状态色 - 警告（橙黄色）
        static let statusWarning = Color(red: 1.0, green: 0.75, blue: 0.3)
        
        /// 状态色 - 错误（红色）
        static let statusError = Color(red: 1.0, green: 0.4, blue: 0.4)
        
        /// 背景色 - 主背景
        static let background = Color(nsColor: .windowBackgroundColor)
        
        /// 背景色 - 次级背景（卡片）
        static let cardBackground = Color(nsColor: .controlBackgroundColor)
        
        /// 背景色 - 侧边栏
        static let sidebarBackground = Color(nsColor: .controlBackgroundColor)
        
        /// 文本色 - 主要文本
        static let primaryText = Color.primary
        
        /// 文本色 - 次要文本
        static let secondaryText = Color.secondary
        
        /// 文本色 - 三级文本（更淡）
        static let tertiaryText = Color(nsColor: .tertiaryLabelColor)
        
        /// 分割线颜色
        static let separator = Color(nsColor: .separatorColor)
        
        /// 毛玻璃材质背景
        static let glassMaterial = Color.clear
        
        // MARK: - 渐变色
        
        /// 上传速度渐变 - 青绿色
        static let uploadGradient = LinearGradient(
            colors: [Color(red: 0.2, green: 0.9, blue: 0.7), Color(red: 0.1, green: 0.7, blue: 0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 下载速度渐变 - 蓝紫色
        static let downloadGradient = LinearGradient(
            colors: [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.3, green: 0.4, blue: 0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 连接状态渐变 - 绿色
        static let connectedGradient = LinearGradient(
            colors: [Color(red: 0.3, green: 0.9, blue: 0.5), Color(red: 0.2, green: 0.7, blue: 0.4)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        /// 网络延迟渐变 - 黄橙色
        static let latencyGradient = LinearGradient(
            colors: [Color(red: 1.0, green: 0.8, blue: 0.3), Color(red: 1.0, green: 0.6, blue: 0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 流量图表上传色
        static let chartUpload = Color(red: 0.2, green: 0.9, blue: 0.7)
        
        /// 流量图表下载色
        static let chartDownload = Color(red: 0.4, green: 0.6, blue: 1.0)
        
        /// 粉紫色渐变（用于总流量）
        static let totalGradient = LinearGradient(
            colors: [Color(red: 0.9, green: 0.4, blue: 0.9), Color(red: 0.6, green: 0.3, blue: 0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 圆环进度条渐变
        static let ringGradient = AngularGradient(
            colors: [
                Color(red: 0.3, green: 0.8, blue: 1.0),
                Color(red: 0.5, green: 0.4, blue: 1.0),
                Color(red: 0.9, green: 0.4, blue: 0.8),
                Color(red: 0.3, green: 0.8, blue: 1.0)
            ],
            center: .center
        )
    }
    
    // MARK: - Typography
    
    enum Typography {
        /// 大标题 - 页面主标题
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
        
        /// 标题 1 - 卡片标题
        static let title1 = Font.system(.title, design: .default, weight: .semibold)
        
        /// 标题 2 - 分组标题
        static let title2 = Font.system(.title2, design: .default, weight: .semibold)
        
        /// 标题 3 - 小节标题
        static let title3 = Font.system(.title3, design: .default, weight: .medium)
        
        /// 正文 - 主要内容
        static let body = Font.system(.body, design: .default)
        
        /// 正文（粗体）
        static let bodyBold = Font.system(.body, design: .default, weight: .semibold)
        
        /// 标注 - 辅助信息
        static let callout = Font.system(.callout, design: .default)
        
        /// 脚注 - 次要信息
        static let footnote = Font.system(.footnote, design: .default)
        
        /// 说明文本 - 最小文本
        static let caption = Font.system(.caption, design: .default)
        
        /// 等宽字体 - 日志、代码
        static let monospaced = Font.system(.body, design: .monospaced)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        /// 超小间距 4pt
        static let xs: CGFloat = 4
        
        /// 小间距 8pt
        static let sm: CGFloat = 8
        
        /// 默认间距 12pt
        static let md: CGFloat = 12
        
        /// 大间距 16pt
        static let lg: CGFloat = 16
        
        /// 超大间距 24pt
        static let xl: CGFloat = 24
        
        /// 特大间距 32pt
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        /// 小圆角 4pt
        static let sm: CGFloat = 4
        
        /// 默认圆角 8pt
        static let md: CGFloat = 8
        
        /// 大圆角 12pt
        static let lg: CGFloat = 12
        
        /// 超大圆角 16pt
        static let xl: CGFloat = 16
    }
    
    // MARK: - Shadow
    
    enum Shadow {
        /// 微妙阴影 - 卡片
        static func card() -> some View {
            EmptyView()
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        
        /// 浮动阴影 - 悬浮元素
        static func elevated() -> some View {
            EmptyView()
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Animation
    
    enum Animation {
        /// 快速动画 - 0.15s
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        
        /// 默认动画 - 0.25s
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        
        /// 慢速动画 - 0.35s
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.35)
        
        /// 弹性动画
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Layout
    
    enum Layout {
        /// 侧边栏宽度
        static let sidebarWidth: CGFloat = 220
        
        /// 卡片最大宽度
        static let cardMaxWidth: CGFloat = 600
        
        /// 工具栏高度
        static let toolbarHeight: CGFloat = 52
    }
}
