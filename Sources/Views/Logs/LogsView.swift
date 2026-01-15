import SwiftUI

/// 日志查看页面
struct LogsView: View {
    @State private var logs: [LogEntry] = []
    @State private var selectedLevel: LogEntry.LogLevel? = nil
    @State private var searchText = ""
    @State private var autoScroll = true
    @State private var isPaused = false

    private let maxLogs = 1000

    var filteredLogs: [LogEntry] {
        var result = logs

        // 按级别过滤
        if let level = selectedLevel {
            result = result.filter { $0.level == level }
        }

        // 按搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText)
                    || log.source?.localizedCaseInsensitiveContains(searchText) == true
            }
        }

        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            toolbar

            Divider()

            // 日志列表
            if filteredLogs.isEmpty {
                emptyView
            } else {
                logsList
            }
        }
        .background(Theme.Colors.background)
        .onAppear {
            startMockLogs()
        }
        .onDisappear {
            isPaused = true
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // 日志级别过滤 - 使用 Picker 节省空间
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(Theme.Colors.secondaryText)

                Picker(
                    "",
                    selection: Binding(
                        get: { selectedLevel?.rawValue ?? "all" },
                        set: { newValue in
                            selectedLevel = LogEntry.LogLevel(rawValue: newValue)
                        }
                    )
                ) {
                    Label("全部", systemImage: "circle.grid.3x3.fill").tag("all")
                    ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                        Label {
                            Text(level.displayName)
                        } icon: {
                            Image(systemName: level.iconName)
                                .foregroundColor(levelColor(level))
                        }.tag(level.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)

            Spacer()

            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .imageScale(.medium)

                TextField("搜索日志内容或来源...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.body)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .help("清除搜索")
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .frame(width: 280)

            Divider()
                .frame(height: 20)

            // 自动滚动开关
            Button(action: { autoScroll.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 16))
                    Text("自动滚动")
                        .font(Theme.Typography.callout)
                }
                .foregroundColor(autoScroll ? Theme.Colors.accent : Theme.Colors.secondaryText)
            }
            .buttonStyle(.plain)
            .help(autoScroll ? "关闭自动滚动" : "开启自动滚动")

            // 暂停/继续
            Button(action: { isPaused.toggle() }) {
                HStack(spacing: 6) {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 16))
                    Text(isPaused ? "继续" : "暂停")
                        .font(Theme.Typography.callout)
                }
                .foregroundColor(isPaused ? Theme.Colors.statusActive : Theme.Colors.accent)
            }
            .buttonStyle(.plain)
            .help(isPaused ? "继续记录日志" : "暂停记录日志")

            // 清空日志
            Button(action: clearLogs) {
                HStack(spacing: 6) {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 16))
                    Text("清空")
                        .font(Theme.Typography.callout)
                }
                .foregroundColor(Theme.Colors.statusError)
            }
            .buttonStyle(.plain)
            .help("清空所有日志")

            Divider()
                .frame(height: 20)

            // 日志数量统计
            HStack(spacing: 6) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                Text("\(filteredLogs.count)")
                    .font(Theme.Typography.monospacedDigit)
                    .monospacedDigit()
            }
            .foregroundColor(Theme.Colors.secondaryText)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Colors.background.opacity(0.95))
    }

    // MARK: - Logs List

    private var logsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredLogs) { log in
                        LogRow(log: log)
                            .id(log.id)
                    }
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .onChange(of: logs.count) { _, _ in
                if autoScroll, let lastLog = filteredLogs.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.cardBackground)
                    .frame(width: 100, height: 100)

                Image(
                    systemName: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass"
                )
                .font(.system(size: 44))
                .foregroundColor(Theme.Colors.tertiaryText)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text(searchText.isEmpty ? "暂无日志记录" : "未找到匹配的日志")
                    .font(Theme.Typography.title3)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.primaryText)

                if searchText.isEmpty {
                    Text("代理服务运行时会在此显示实时日志")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.tertiaryText)
                } else {
                    Text("尝试调整搜索关键词或日志级别过滤")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.tertiaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
    }

    // MARK: - Helper Methods

    private func levelColor(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .trace: return Theme.Colors.tertiaryText
        case .debug: return Theme.Colors.accent
        case .info: return Theme.Colors.statusActive
        case .warn: return Theme.Colors.statusWarning
        case .error: return Theme.Colors.statusError
        }
    }

    private func clearLogs() {
        withAnimation {
            logs.removeAll()
        }
    }

    // MARK: - Mock Data

    private func startMockLogs() {
        // 添加初始日志
        logs = [
            LogEntry(level: .info, message: "Phase 已启动", source: "app"),
            LogEntry(level: .info, message: "正在加载配置文件...", source: "config"),
            LogEntry(
                level: .debug, message: "配置文件路径: ~/Library/Application Support/Phase/config.json",
                source: "config"),
        ]

        // 模拟定时添加新日志
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard !isPaused else { return }

            addMockLog()

            // 限制日志数量
            if logs.count > maxLogs {
                logs.removeFirst(logs.count - maxLogs)
            }
        }
    }

    private func addMockLog() {
        let messages = [
            ("sing-box 进程已启动", LogEntry.LogLevel.info),
            ("连接到代理服务器: hk01.example.com:8388", LogEntry.LogLevel.info),
            ("DNS 查询: google.com", LogEntry.LogLevel.debug),
            ("建立连接: 192.168.1.100:443", LogEntry.LogLevel.trace),
            ("接收数据: 1.2 KB", LogEntry.LogLevel.trace),
            ("发送数据: 0.5 KB", LogEntry.LogLevel.trace),
            ("连接已关闭", LogEntry.LogLevel.debug),
            ("规则匹配: google.com -> PROXY", LogEntry.LogLevel.info),
            ("规则匹配: baidu.com -> DIRECT", LogEntry.LogLevel.info),
            ("规则匹配: ad.doubleclick.net -> REJECT", LogEntry.LogLevel.warn),
            ("代理服务器响应超时，正在重试...", LogEntry.LogLevel.warn),
            ("连接失败: timeout", LogEntry.LogLevel.error),
        ]

        let (message, level) = messages.randomElement()!
        let log = LogEntry(level: level, message: message, source: "sing-box")

        logs.append(log)
    }
}

// MARK: - Log Row

private struct LogRow: View {
    let log: LogEntry
    @State private var isHovered = false
    @State private var showCopied = false

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // 时间戳
            Text(timeFormatter.string(from: log.timestamp))
                .font(Theme.Typography.monospacedDigit)
                .foregroundColor(Theme.Colors.tertiaryText)
                .frame(width: 95, alignment: .leading)
                .monospacedDigit()

            // 级别标签
            HStack(spacing: 4) {
                Image(systemName: log.level.iconName)
                    .font(.system(size: 10, weight: .semibold))
                Text(log.level.displayName)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(levelColor.opacity(0.9))
            .cornerRadius(6)
            .frame(width: 75)

            // 来源标签
            if let source = log.source {
                Text(source)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.Colors.cardBackground.opacity(0.6))
                    .cornerRadius(6)
                    .frame(minWidth: 70, alignment: .center)
            }

            // 消息内容
            Text(log.message)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            // 复制按钮
            if isHovered {
                Button(action: copyLog) {
                    Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(
                            showCopied ? Theme.Colors.statusActive : Theme.Colors.secondaryText)
                }
                .buttonStyle(.plain)
                .help("复制日志")
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Theme.Colors.cardBackground.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
            if !hovering {
                showCopied = false
            }
        }
    }

    private var levelColor: Color {
        switch log.level {
        case .trace: return Color.gray
        case .debug: return Theme.Colors.accent
        case .info: return Theme.Colors.statusActive
        case .warn: return Theme.Colors.statusWarning
        case .error: return Theme.Colors.statusError
        }
    }

    private func copyLog() {
        let logText =
            "\(timeFormatter.string(from: log.timestamp)) [\(log.level.displayName)] \(log.source ?? "") \(log.message)"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logText, forType: .string)

        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}

#Preview {
    LogsView()
        .frame(width: 900, height: 600)
}
