import Foundation

/// 代理节点模型
struct ProxyNode: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: ProxyType
    let server: String
    let port: Int
    var latency: Int?
    
    enum ProxyType: String, Codable {
        case shadowsocks = "Shadowsocks"
        case vmess = "VMess"
        case trojan = "Trojan"
        case hysteria2 = "Hysteria2"
        case vless = "VLESS"
        case tuic = "TUIC"
        
        var displayName: String { rawValue }
    }
    
    init(id: UUID = UUID(), name: String, type: ProxyType, server: String, port: Int, latency: Int? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.server = server
        self.port = port
        self.latency = latency
    }
}

/// 流量统计模型
struct TrafficStats: Codable {
    var uploadBytes: Int64
    var downloadBytes: Int64
    
    var uploadFormatted: String {
        ByteCountFormatter.string(fromByteCount: uploadBytes, countStyle: .binary)
    }
    
    var downloadFormatted: String {
        ByteCountFormatter.string(fromByteCount: downloadBytes, countStyle: .binary)
    }
}

/// 代理配置模型
struct ProxyConfig: Codable {
    var selectedNodeId: UUID?
    var isSystemProxyEnabled: Bool
    var nodes: [ProxyNode]
    
    init(selectedNodeId: UUID? = nil, isSystemProxyEnabled: Bool = false, nodes: [ProxyNode] = []) {
        self.selectedNodeId = selectedNodeId
        self.isSystemProxyEnabled = isSystemProxyEnabled
        self.nodes = nodes
    }
}
