import Foundation

/// 代理模式
enum ProxyMode: String, Codable, CaseIterable {
    case direct = "直连"      // 所有流量直连
    case rule = "规则"        // 根据规则分流
    case global = "全局"      // 所有流量走代理
    
    var icon: String {
        switch self {
        case .direct: return "arrow.right"
        case .rule: return "list.bullet"
        case .global: return "globe"
        }
    }
    
    var description: String {
        switch self {
        case .direct: return "所有流量直接连接"
        case .rule: return "根据规则智能分流"
        case .global: return "所有流量通过代理"
        }
    }
}

/// 代理节点模型
struct ProxyNode: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: ProxyType
    let server: String
    let port: Int
    var latency: Int?
    
    // Shadowsocks 配置
    var method: String?        // 加密方法
    var password: String?      // 密码
    
    // VMess/VLESS 配置
    var uuid: String?          // UUID
    var alterId: Int?          // VMess alterId
    var security: String?      // 加密方式
    var network: String?       // 传输协议
    
    // 通用 TLS 配置
    var tls: Bool?             // 是否启用 TLS
    var sni: String?           // TLS SNI
    
    enum ProxyType: String, Codable {
        case shadowsocks = "Shadowsocks"
        case vmess = "VMess"
        case trojan = "Trojan"
        case hysteria2 = "Hysteria2"
        case vless = "VLESS"
        case tuic = "TUIC"
        
        var displayName: String { rawValue }
    }
    
    init(id: UUID = UUID(), name: String, type: ProxyType, server: String, port: Int, latency: Int? = nil,
         method: String? = nil, password: String? = nil,
         uuid: String? = nil, alterId: Int? = nil, security: String? = nil, network: String? = nil,
         tls: Bool? = nil, sni: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.server = server
        self.port = port
        self.latency = latency
        self.method = method
        self.password = password
        self.uuid = uuid
        self.alterId = alterId
        self.security = security
        self.network = network
        self.tls = tls
        self.sni = sni
    }
}

/// 流量统计模型
struct TrafficStats: Codable {
    var uploadBytes: Int64
    var downloadBytes: Int64
    
    var uploadFormatted: String {
        formatBytes(uploadBytes)
    }
    
    var downloadFormatted: String {
        formatBytes(downloadBytes)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let kb = Double(bytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.2f KB", kb)
        } else {
            return "0 KB"
        }
    }
}

/// 代理配置（用于持久化）
struct ProxyConfig: Codable {
    let selectedNodeId: UUID?
    let proxyMode: ProxyMode?
}
