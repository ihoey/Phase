import Foundation

/// 订阅服务
/// 负责订阅的添加、更新、解析
class SubscriptionService {
    static let shared = SubscriptionService()
    
    private let subscriptionsFileName = "subscriptions.json"
    
    private var subscriptionsURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let phaseDir = appSupport.appendingPathComponent("Phase", isDirectory: true)
        try? FileManager.default.createDirectory(at: phaseDir, withIntermediateDirectories: true)
        return phaseDir.appendingPathComponent(subscriptionsFileName)
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 加载订阅列表
    func loadSubscriptions() -> [Subscription] {
        guard let data = try? Data(contentsOf: subscriptionsURL),
              let subscriptions = try? JSONDecoder().decode([Subscription].self, from: data) else {
            return []
        }
        return subscriptions
    }
    
    /// 保存订阅列表
    func saveSubscriptions(_ subscriptions: [Subscription]) {
        guard let data = try? JSONEncoder().encode(subscriptions) else { return }
        try? data.write(to: subscriptionsURL)
    }
    
    /// 更新订阅（获取节点）
    func updateSubscription(_ subscription: Subscription) async throws -> [ProxyNode] {
        print("🔄 更新订阅: \(subscription.name)")
        
        guard let url = URL(string: subscription.url) else {
            throw SubscriptionError.invalidURL
        }
        
        // 下载订阅内容
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.downloadFailed
        }
        
        // 解析订阅
        let nodes = try parseSubscription(data)
        
        print("✅ 订阅更新成功，获取到 \(nodes.count) 个节点")
        
        return nodes
    }
    
    // MARK: - Private Methods
    
    /// 解析订阅内容
    private func parseSubscription(_ data: Data) throws -> [ProxyNode] {
        // 先尝试直接解析原始数据
        if let text = String(data: data, encoding: .utf8) {
            let nodes = parseNodes(from: text)
            if !nodes.isEmpty {
                return nodes
            }
        }
        
        // 如果直接解析失败，尝试 Base64 解码后再解析
        if let base64String = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           let decodedData = Data(base64Encoded: base64String),
           let decodedText = String(data: decodedData, encoding: .utf8) {
            let nodes = parseNodes(from: decodedText)
            if !nodes.isEmpty {
                print("✅ Base64 解码成功，解析到 \(nodes.count) 个节点")
                return nodes
            }
        }
        
        throw SubscriptionError.parseFailed
    }
    
    /// 从文本中解析节点
    private func parseNodes(from text: String) -> [ProxyNode] {
        let lines = text.components(separatedBy: .newlines)
        var nodes: [ProxyNode] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.hasPrefix("ss://") {
                if let node = parseShadowsocks(trimmed) {
                    nodes.append(node)
                }
            } else if trimmed.hasPrefix("vmess://") {
                if let node = parseVMess(trimmed) {
                    nodes.append(node)
                }
            } else if trimmed.hasPrefix("trojan://") {
                if let node = parseTrojan(trimmed) {
                    nodes.append(node)
                }
            }
        }
        
        return nodes
    }
    
    /// 解析 Shadowsocks 链接
    /// 支持两种格式：
    /// 1. 旧格式: ss://base64(method:password@server:port)#name
    /// 2. SIP002: ss://base64(method:password)@server:port#name
    private func parseShadowsocks(_ url: String) -> ProxyNode? {
        guard url.hasPrefix("ss://") else { return nil }
        
        let content = String(url.dropFirst(5))
        
        // 查找备注（#后面的内容）
        var name = "Shadowsocks"
        var mainContent = content
        
        if let hashIndex = content.firstIndex(of: "#") {
            let fragment = content[content.index(after: hashIndex)...]
            if let decoded = fragment.removingPercentEncoding {
                name = decoded
            }
            mainContent = String(content[..<hashIndex])
        }
        
        // 检查是否是 SIP002 格式（包含明文的 @server:port）
        if let atIndex = mainContent.firstIndex(of: "@") {
            // SIP002 格式: base64(method:password)@server:port
            let authPart = String(mainContent[..<atIndex])
            let serverPart = String(mainContent[mainContent.index(after: atIndex)...])
            
            // 解析 Base64 编码的认证信息
            let normalizedBase64 = authPart
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let paddingLength = (4 - normalizedBase64.count % 4) % 4
            let paddedBase64 = normalizedBase64 + String(repeating: "=", count: paddingLength)
            
            guard let decoded = Data(base64Encoded: paddedBase64),
                  let decodedString = String(data: decoded, encoding: .utf8) else {
                print("⚠️ Shadowsocks SIP002 Base64 解码失败: \(authPart)")
                return nil
            }
            
            // 解析 method:password
            let authParts = decodedString.components(separatedBy: ":")
            guard authParts.count == 2 else {
                print("⚠️ Shadowsocks SIP002 认证格式无效: \(decodedString)")
                return nil
            }
            
            let method = authParts[0]
            let password = authParts[1]
            
            // 解析服务器和端口
            let serverParts = serverPart.components(separatedBy: ":")
            guard serverParts.count == 2,
                  let port = Int(serverParts[1]) else {
                print("⚠️ Shadowsocks SIP002 服务器地址无效: \(serverPart)")
                return nil
            }
            
            return ProxyNode(
                name: name,
                type: .shadowsocks,
                server: serverParts[0],
                port: port,
                method: method,
                password: password
            )
        } else {
            // 旧格式: 整体 Base64 编码
            let normalizedBase64 = mainContent
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            
            // 添加必要的 padding
            let paddingLength = (4 - normalizedBase64.count % 4) % 4
            let paddedBase64 = normalizedBase64 + String(repeating: "=", count: paddingLength)
            
            guard let decoded = Data(base64Encoded: paddedBase64),
                  let decodedString = String(data: decoded, encoding: .utf8) else {
                print("⚠️ Shadowsocks Base64 解码失败: \(mainContent)")
                return nil
            }
            
            // 解析 method:password@server:port
            let parts = decodedString.components(separatedBy: "@")
            guard parts.count == 2 else {
                print("⚠️ Shadowsocks 格式无效: \(decodedString)")
                return nil
            }
            
            // 解析 method:password
            let authParts = parts[0].components(separatedBy: ":")
            guard authParts.count == 2 else {
                print("⚠️ Shadowsocks 认证格式无效: \(parts[0])")
                return nil
            }
            
            let method = authParts[0]
            let password = authParts[1]
            
            let serverParts = parts[1].components(separatedBy: ":")
            guard serverParts.count == 2,
                  let port = Int(serverParts[1]) else {
                print("⚠️ Shadowsocks 服务器地址无效: \(parts[1])")
                return nil
            }
            
            return ProxyNode(
                name: name,
                type: .shadowsocks,
                server: serverParts[0],
                port: port,
                method: method,
                password: password
            )
        }
    }
    
    /// 解析 VMess 链接
    private func parseVMess(_ url: String) -> ProxyNode? {
        guard url.hasPrefix("vmess://") else { return nil }
        
        let base64Content = String(url.dropFirst(8))
        
        // 处理 URL-safe base64
        let normalizedBase64 = base64Content
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 添加必要的 padding
        let paddingLength = (4 - normalizedBase64.count % 4) % 4
        let paddedBase64 = normalizedBase64 + String(repeating: "=", count: paddingLength)
        
        guard let decoded = Data(base64Encoded: paddedBase64),
              let json = try? JSONSerialization.jsonObject(with: decoded) as? [String: Any] else {
            print("⚠️ VMess Base64 解码或 JSON 解析失败")
            return nil
        }
        
        guard let server = json["add"] as? String,
              let port = json["port"] as? Int else {
            // 尝试 port 是字符串的情况
            guard let server = json["add"] as? String,
                  let portString = json["port"] as? String,
                  let port = Int(portString) else {
                print("⚠️ VMess 缺少必要字段: add, port")
                return nil
            }
            
            let name = json["ps"] as? String ?? "VMess"
            return ProxyNode(
                name: name,
                type: .vmess,
                server: server,
                port: port
            )
        }
        
        let name = json["ps"] as? String ?? "VMess"
        
        return ProxyNode(
            name: name,
            type: .vmess,
            server: server,
            port: port
        )
    }
    
    /// 解析 Trojan 链接
    private func parseTrojan(_ url: String) -> ProxyNode? {
        guard url.hasPrefix("trojan://") else { return nil }
        
        let content = String(url.dropFirst(9))
        
        // 查找备注
        var name = "Trojan"
        var mainContent = content
        
        if let hashIndex = content.firstIndex(of: "#") {
            let fragment = content[content.index(after: hashIndex)...]
            if let decoded = fragment.removingPercentEncoding {
                name = decoded
            }
            mainContent = String(content[..<hashIndex])
        }
        
        // 解析 password@server:port
        let parts = mainContent.components(separatedBy: "@")
        guard parts.count == 2 else { return nil }
        
        let serverParts = parts[1].components(separatedBy: ":")
        guard serverParts.count >= 2,
              let port = Int(serverParts[1].components(separatedBy: "?").first ?? "") else {
            return nil
        }
        
        return ProxyNode(
            name: name,
            type: .trojan,
            server: serverParts[0],
            port: port
        )
    }
}

// MARK: - Error Types

enum SubscriptionError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case invalidFormat
    case parseFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的订阅地址"
        case .downloadFailed:
            return "下载订阅失败"
        case .invalidFormat:
            return "订阅格式无效"
        case .parseFailed:
            return "解析订阅失败"
        }
    }
}
