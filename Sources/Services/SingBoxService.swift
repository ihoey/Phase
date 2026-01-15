import Foundation

/// sing-box 代理服务管理器
/// 负责启动、停止和管理 sing-box 进程
class SingBoxService {
    static let shared = SingBoxService()
    
    private var process: Process?
    private var configURL: URL
    
    private init() {
        // 配置文件路径
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let phaseDir = appSupport.appendingPathComponent("Phase", isDirectory: true)
        try? FileManager.default.createDirectory(at: phaseDir, withIntermediateDirectories: true)
        
        configURL = phaseDir.appendingPathComponent("config.json")
    }
    
    // MARK: - Public Methods
    
    /// 启动 sing-box
    func start(config: SingBoxConfig) throws {
        guard process == nil else {
            print("⚠️ sing-box 已在运行")
            return
        }
        
        // 保存配置文件
        try saveConfig(config)
        
        // 获取 sing-box 二进制路径
        guard let binaryPath = singBoxBinaryPath() else {
            throw SingBoxError.binaryNotFound
        }
        
        // 创建进程
        let newProcess = Process()
        newProcess.executableURL = URL(fileURLWithPath: binaryPath)
        newProcess.arguments = ["run", "-c", configURL.path]
        
        // 重定向输出（可选，用于调试）
        let outputPipe = Pipe()
        newProcess.standardOutput = outputPipe
        newProcess.standardError = outputPipe
        
        // 监听输出
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("📦 sing-box: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
        
        // 启动进程
        try newProcess.run()
        process = newProcess
        
        print("🚀 sing-box 已启动 (PID: \(newProcess.processIdentifier))")
    }
    
    /// 停止 sing-box
    func stop() {
        guard let process = process else {
            print("⚠️ sing-box 未在运行")
            return
        }
        
        process.terminate()
        
        // 等待进程结束（最多等待 3 秒）
        DispatchQueue.global().async {
            for _ in 0..<30 {
                if !process.isRunning {
                    break
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // 如果还未结束，强制终止
            if process.isRunning {
                process.interrupt()
            }
        }
        
        self.process = nil
        print("⏹️ sing-box 已停止")
    }
    
    /// 检查 sing-box 是否在运行
    var isRunning: Bool {
        return process?.isRunning ?? false
    }
    
    // MARK: - Private Methods
    
    private func singBoxBinaryPath() -> String? {
        // 方案 1: 开发环境 - Sources/Resources 目录
        let currentDir = FileManager.default.currentDirectoryPath
        let devPaths = [
            currentDir + "/Sources/Resources/sing-box",
            currentDir + "/.build/debug/Phase_Phase.resources/sing-box",
        ]
        
        for path in devPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ 找到 sing-box: \(path)")
                return path
            }
        }
        
        // 方案 2: 从 Bundle Resources 目录加载（发布版本）
        if let resourcePath = Bundle.main.resourcePath {
            let binaryPath = resourcePath + "/sing-box"
            if FileManager.default.fileExists(atPath: binaryPath) {
                print("✅ 找到 sing-box: \(binaryPath)")
                return binaryPath
            }
        }
        
        // 方案 3: 从系统路径查找（如果用户已安装）
        let systemPaths = [
            "/usr/local/bin/sing-box",
            "/opt/homebrew/bin/sing-box",
            "/usr/bin/sing-box"
        ]
        
        for path in systemPaths {
            if FileManager.default.fileExists(atPath: path) {
                print("✅ 找到 sing-box: \(path)")
                return path
            }
        }
        
        print("❌ 未找到 sing-box 二进制文件")
        print("💡 请将 sing-box 放置到以下任一位置：")
        print("   - \(currentDir)/Sources/Resources/sing-box")
        print("   - /usr/local/bin/sing-box")
        print("   - /opt/homebrew/bin/sing-box")
        
        return nil
    }
    
    private func saveConfig(_ config: SingBoxConfig) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }
}

// MARK: - sing-box 配置模型

/// sing-box 配置结构
/// 参考: https://sing-box.sagernet.org/configuration/
struct SingBoxConfig: Codable {
    let log: LogConfig
    let dns: DNSConfig?
    let inbounds: [Inbound]
    let outbounds: [Outbound]
    let route: RouteConfig?
    
    struct LogConfig: Codable {
        let level: String // trace, debug, info, warn, error
        let timestamp: Bool
    }
    
    struct DNSConfig: Codable {
        let servers: [DNSServer]
        
        struct DNSServer: Codable {
            let address: String
            let tag: String?
        }
    }
    
    struct Inbound: Codable {
        let type: String // socks, http, mixed
        let tag: String
        let listen: String
        let listenPort: Int
        
        enum CodingKeys: String, CodingKey {
            case type, tag, listen
            case listenPort = "listen_port"
        }
    }
    
    struct Outbound: Codable {
        let type: String // direct, block, shadowsocks, vmess, trojan, etc.
        let tag: String
        let server: String?
        let serverPort: Int?
        
        // Shadowsocks specific
        let method: String?
        let password: String?
        
        enum CodingKeys: String, CodingKey {
            case type, tag, server
            case serverPort = "server_port"
            case method, password
        }
    }
    
    struct RouteConfig: Codable {
        let rules: [Rule]
        let final: String
        
        struct Rule: Codable {
            let domain: [String]?
            let ipCidr: [String]?
            let outbound: String
            
            enum CodingKeys: String, CodingKey {
                case domain
                case ipCidr = "ip_cidr"
                case outbound
            }
        }
    }
}

// MARK: - 错误定义

enum SingBoxError: Error, LocalizedError {
    case binaryNotFound
    case configInvalid
    case alreadyRunning
    case notRunning
    
    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "未找到 sing-box 二进制文件"
        case .configInvalid:
            return "配置文件无效"
        case .alreadyRunning:
            return "sing-box 已在运行"
        case .notRunning:
            return "sing-box 未在运行"
        }
    }
}

// MARK: - 配置生成辅助方法

extension SingBoxConfig {
    /// 创建默认配置
    static func createDefault(node: ProxyNode? = nil) -> SingBoxConfig {
        // 入站：混合代理（HTTP + SOCKS5）
        let inbound = Inbound(
            type: "mixed",
            tag: "mixed-in",
            listen: "127.0.0.1",
            listenPort: 7890
        )
        
        // 出站
        var outbounds: [Outbound] = []
        
        // 如果有选中节点，添加代理出站
        if let node = node {
            switch node.type {
            case .shadowsocks:
                outbounds.append(Outbound(
                    type: "shadowsocks",
                    tag: "proxy",
                    server: node.server,
                    serverPort: node.port,
                    method: "aes-256-gcm",
                    password: "password_placeholder"
                ))
            default:
                // TODO: 支持其他协议
                break
            }
        }
        
        // 直连出站
        outbounds.append(Outbound(
            type: "direct",
            tag: "direct",
            server: nil,
            serverPort: nil,
            method: nil,
            password: nil
        ))
        
        // 阻断出站
        outbounds.append(Outbound(
            type: "block",
            tag: "block",
            server: nil,
            serverPort: nil,
            method: nil,
            password: nil
        ))
        
        return SingBoxConfig(
            log: LogConfig(level: "info", timestamp: true),
            dns: DNSConfig(servers: [
                DNSConfig.DNSServer(address: "223.5.5.5", tag: "ali"),
                DNSConfig.DNSServer(address: "8.8.8.8", tag: "google")
            ]),
            inbounds: [inbound],
            outbounds: outbounds,
            route: RouteConfig(
                rules: [
                    RouteConfig.Rule(
                        domain: ["geosite:cn"],
                        ipCidr: nil,
                        outbound: "direct"
                    ),
                    RouteConfig.Rule(
                        domain: nil,
                        ipCidr: ["geoip:cn", "geoip:private"],
                        outbound: "direct"
                    )
                ],
                final: node != nil ? "proxy" : "direct"
            )
        )
    }
}
