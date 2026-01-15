import Foundation

// MARK: - 进程流量统计

/// 按进程统计的流量
struct ProcessTraffic: Identifiable, Codable {
    let id: String  // 进程名或 bundle identifier
    let name: String
    let icon: String?  // 应用图标路径
    var uploadBytes: Int64
    var downloadBytes: Int64
    var lastUpdate: Date
    
    var totalBytes: Int64 {
        uploadBytes + downloadBytes
    }
}

// MARK: - 主机流量统计

/// 按主机（域名/IP）统计的流量
struct HostTraffic: Identifiable, Codable {
    let id: String  // 域名或 IP
    let host: String
    var uploadBytes: Int64
    var downloadBytes: Int64
    var connectionCount: Int
    var lastAccess: Date
    
    var totalBytes: Int64 {
        uploadBytes + downloadBytes
    }
}

// MARK: - 接口流量统计

/// 按网络接口统计的流量
struct InterfaceTraffic: Identifiable, Codable {
    let id: String  // 接口名称，如 en0, utun3
    let name: String
    let type: InterfaceType
    var uploadBytes: Int64
    var downloadBytes: Int64
    
    enum InterfaceType: String, Codable {
        case wifi = "Wi-Fi"
        case ethernet = "以太网"
        case vpn = "VPN"
        case cellular = "蜂窝网络"
        case other = "其他"
    }
    
    var totalBytes: Int64 {
        uploadBytes + downloadBytes
    }
}

// MARK: - 代理流量统计

/// 按代理类型统计的流量
struct ProxyTraffic: Identifiable, Codable {
    let id: String
    let proxyName: String
    let proxyType: String  // direct, proxy, reject
    var uploadBytes: Int64
    var downloadBytes: Int64
    var connectionCount: Int
    
    var totalBytes: Int64 {
        uploadBytes + downloadBytes
    }
}

// MARK: - 日流量统计

/// 按天统计的流量（用于趋势图）
struct DailyTraffic: Identifiable, Codable {
    let id: String  // 日期字符串 YYYY-MM-DD
    let date: Date
    var uploadBytes: Int64
    var downloadBytes: Int64
    
    var totalBytes: Int64 {
        uploadBytes + downloadBytes
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 规则匹配统计

/// 规则匹配次数统计
struct RuleStats: Identifiable, Codable {
    let id: String
    let ruleName: String
    let ruleType: String  // DOMAIN, DOMAIN-SUFFIX, IP-CIDR, GEOIP 等
    let action: String    // DIRECT, PROXY, REJECT
    var matchCount: Int
    var lastMatch: Date?
    
    var matchCountFormatted: String {
        if matchCount >= 1000000 {
            return String(format: "%.1fM", Double(matchCount) / 1000000.0)
        } else if matchCount >= 1000 {
            return String(format: "%.1fK", Double(matchCount) / 1000.0)
        } else {
            return "\(matchCount)"
        }
    }
}

// MARK: - 综合流量追踪器

/// 综合流量追踪数据
class TrafficTracker: ObservableObject, Codable {
    @Published var processes: [ProcessTraffic] = []
    @Published var hosts: [HostTraffic] = []
    @Published var interfaces: [InterfaceTraffic] = []
    @Published var proxies: [ProxyTraffic] = []
    @Published var dailyHistory: [DailyTraffic] = []
    @Published var rules: [RuleStats] = []
    
    enum CodingKeys: String, CodingKey {
        case processes, hosts, interfaces, proxies, dailyHistory, rules
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        processes = try container.decode([ProcessTraffic].self, forKey: .processes)
        hosts = try container.decode([HostTraffic].self, forKey: .hosts)
        interfaces = try container.decode([InterfaceTraffic].self, forKey: .interfaces)
        proxies = try container.decode([ProxyTraffic].self, forKey: .proxies)
        dailyHistory = try container.decode([DailyTraffic].self, forKey: .dailyHistory)
        rules = try container.decode([RuleStats].self, forKey: .rules)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(processes, forKey: .processes)
        try container.encode(hosts, forKey: .hosts)
        try container.encode(interfaces, forKey: .interfaces)
        try container.encode(proxies, forKey: .proxies)
        try container.encode(dailyHistory, forKey: .dailyHistory)
        try container.encode(rules, forKey: .rules)
    }
    
    init() {}
    
    // MARK: - 计算属性
    
    /// 获取最近7天的流量数据
    var last7Days: [DailyTraffic] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        return dailyHistory
            .filter { $0.date >= sevenDaysAgo && $0.date <= today }
            .sorted { $0.date < $1.date }
    }
    
    /// 日均流量
    var dailyAverage: Int64 {
        guard !last7Days.isEmpty else { return 0 }
        let total = last7Days.reduce(0) { $0 + $1.totalBytes }
        return total / Int64(last7Days.count)
    }
    
    /// Top 5 进程
    var topProcesses: [ProcessTraffic] {
        Array(processes.sorted { $0.totalBytes > $1.totalBytes }.prefix(5))
    }
    
    /// Top 10 主机
    var topHosts: [HostTraffic] {
        Array(hosts.sorted { $0.totalBytes > $1.totalBytes }.prefix(10))
    }
    
    /// Top 10 规则
    var topRules: [RuleStats] {
        Array(rules.sorted { $0.matchCount > $1.matchCount }.prefix(10))
    }
    
    // MARK: - 数据管理
    
    /// 重置规则统计
    func resetRuleStats() {
        rules.removeAll()
    }
    
    /// 清空所有数据
    func clearAll() {
        processes.removeAll()
        hosts.removeAll()
        interfaces.removeAll()
        proxies.removeAll()
        dailyHistory.removeAll()
        rules.removeAll()
    }
    
    /// 添加模拟数据（用于测试）
    func addMockData() {
        // 模拟进程数据
        processes = [
            ProcessTraffic(id: "com.apple.Safari", name: "Safari", icon: nil, 
                          uploadBytes: 1024 * 1024 * 25, downloadBytes: 1024 * 1024 * 150, 
                          lastUpdate: Date()),
            ProcessTraffic(id: "com.google.Chrome", name: "Chrome", icon: nil,
                          uploadBytes: 1024 * 1024 * 18, downloadBytes: 1024 * 1024 * 120,
                          lastUpdate: Date()),
            ProcessTraffic(id: "com.electron.wechat", name: "WeChat", icon: nil,
                          uploadBytes: 1024 * 1024 * 12, downloadBytes: 1024 * 1024 * 45,
                          lastUpdate: Date()),
        ]
        
        // 模拟主机数据
        hosts = [
            HostTraffic(id: "google.com", host: "google.com",
                       uploadBytes: 1024 * 1024 * 15, downloadBytes: 1024 * 1024 * 85,
                       connectionCount: 1250, lastAccess: Date()),
            HostTraffic(id: "github.com", host: "github.com",
                       uploadBytes: 1024 * 1024 * 8, downloadBytes: 1024 * 1024 * 42,
                       connectionCount: 680, lastAccess: Date()),
            HostTraffic(id: "api.openai.com", host: "api.openai.com",
                       uploadBytes: 1024 * 1024 * 5, downloadBytes: 1024 * 1024 * 28,
                       connectionCount: 320, lastAccess: Date()),
        ]
        
        // 模拟代理统计
        proxies = [
            ProxyTraffic(id: "proxy", proxyName: "代理", proxyType: "proxy",
                        uploadBytes: 1024 * 1024 * 45, downloadBytes: 1024 * 1024 * 280,
                        connectionCount: 2150),
            ProxyTraffic(id: "direct", proxyName: "直连", proxyType: "direct",
                        uploadBytes: 1024 * 1024 * 8, downloadBytes: 1024 * 1024 * 35,
                        connectionCount: 480),
        ]
        
        // 模拟7天流量
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        dailyHistory = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dateString = ISO8601DateFormatter().string(from: date)
            return DailyTraffic(
                id: dateString,
                date: date,
                uploadBytes: Int64.random(in: 1024*1024*10...1024*1024*50),
                downloadBytes: Int64.random(in: 1024*1024*50...1024*1024*200)
            )
        }.reversed()
        
        // 模拟规则统计
        rules = [
            RuleStats(id: "1", ruleName: "DOMAIN-SUFFIX,google.com", ruleType: "DOMAIN-SUFFIX",
                     action: "PROXY", matchCount: 15680, lastMatch: Date()),
            RuleStats(id: "2", ruleName: "DOMAIN-SUFFIX,github.com", ruleType: "DOMAIN-SUFFIX",
                     action: "PROXY", matchCount: 8420, lastMatch: Date()),
            RuleStats(id: "3", ruleName: "GEOIP,CN", ruleType: "GEOIP",
                     action: "DIRECT", matchCount: 6250, lastMatch: Date()),
            RuleStats(id: "4", ruleName: "DOMAIN-SUFFIX,apple.com", ruleType: "DOMAIN-SUFFIX",
                     action: "DIRECT", matchCount: 4180, lastMatch: Date()),
        ]
    }
}
