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
                Text("级别")
                    .font(Theme.Typography.callout)
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
                    Text("全部").tag("all")
                    ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                        HStack {
                            Image(systemName: level.iconName)
                            Text(level.displayName)
                        }.tag(level.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }

            Spacer()

            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.Colors.tertiaryText)

                TextField("搜索日志", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(Theme.Typography.body)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .frame(width: 250)

            // 自动滚动开关
            Toggle(isOn: $autoScroll) {
                HStack(spacing: 4) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 14))
                    Text("自动滚动")
                        .font(Theme.Typography.callout)
                }
            }
            .toggleStyle(.button)
            .tint(Theme.Colors.accent)

            // 暂停/继续
            Button(action: { isPaused.toggle() }) {
                Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isPaused ? Theme.Colors.statusActive : Theme.Colors.accent)
            }
            .buttonStyle(.plain)

            // 清空日志
            Button(action: clearLogs) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.statusError)
            }
            .buttonStyle(.plain)

            // 日志数量
            Text("\(filteredLogs.count) 条")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Logs List

    private var logsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredLogs) { log in
                        LogRow(log: log)
                            .id(log.id)

                        Divider()
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .onChange(of: logs.count) { _, _ in
                if autoScroll, let lastLog = filteredLogs.last {
                    withAnimation {
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.tertiaryText)

            Text(searchText.isEmpty ? "暂无日志" : "未找到匹配日志")
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.secondaryText)

            if searchText.isEmpty {
                Text("代理运行时会在此显示日志")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // 时间戳
            Text(timeFormatter.string(from: log.timestamp))
                .font(Theme.Typography.monospaced)
                .foregroundColor(Theme.Colors.tertiaryText)
                .frame(width: 90, alignment: .leading)
                .monospacedDigit()

            // 级别图标
            Image(systemName: log.level.iconName)
                .font(.system(size: 12))
                .foregroundColor(levelColor)
                .frame(width: 20)

            // 来源
            if let source = log.source {
                Text("[\(source)]")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.tertiaryText)
                    .frame(width: 80, alignment: .leading)
            }

            // 消息
            Text(log.message)
                .font(Theme.Typography.monospaced)
                .foregroundColor(Theme.Colors.primaryText)
                .textSelection(.enabled)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    private var levelColor: Color {
        switch log.level {
        case .trace: return Theme.Colors.tertiaryText
        case .debug: return Theme.Colors.accent
        case .info: return Theme.Colors.statusActive
        case .warn: return Theme.Colors.statusWarning
        case .error: return Theme.Colors.statusError
        }
    }
}

#Preview {
    LogsView()
        .frame(width: 900, height: 600)
}
