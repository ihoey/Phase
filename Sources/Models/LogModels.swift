import Foundation

/// 日志条目模型
struct LogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String?
    
    enum LogLevel: String, CaseIterable, Codable {
        case trace = "TRACE"
        case debug = "DEBUG"
        case info = "INFO"
        case warn = "WARN"
        case error = "ERROR"
        
        var displayName: String { rawValue }
        
        var color: String {
            switch self {
            case .trace: return "gray"
            case .debug: return "blue"
            case .info: return "green"
            case .warn: return "orange"
            case .error: return "red"
            }
        }
        
        var iconName: String {
            switch self {
            case .trace: return "circle"
            case .debug: return "ant.circle"
            case .info: return "info.circle"
            case .warn: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        message: String,
        source: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.source = source
    }
}
