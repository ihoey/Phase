import Foundation
import SystemConfiguration

/// 系统代理管理器
/// 负责设置和恢复 macOS 系统级 HTTP/HTTPS/SOCKS 代理
class SystemProxyManager {
    static let shared = SystemProxyManager()
    
    private var originalProxySettings: [String: Any] = [:]
    private let proxyHost = "127.0.0.1"
    private let httpPort = 7890  // sing-box 默认端口
    private let socksPort = 7890
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 启用系统代理
    func enableProxy() throws {
        print("🔧 启用系统代理...")
        
        // 保存原始设置
        saveOriginalSettings()
        
        // 设置新的代理
        try setSystemProxy(enabled: true)
        
        print("✅ 系统代理已启用")
    }
    
    /// 禁用系统代理（恢复原始设置）
    func disableProxy() throws {
        print("🔧 禁用系统代理...")
        
        try setSystemProxy(enabled: false)
        
        // 清空保存的设置
        originalProxySettings.removeAll()
        
        print("✅ 系统代理已禁用")
    }
    
    /// 检查系统代理是否已启用
    func isProxyEnabled() -> Bool {
        guard let proxies = getSystemProxies() else { return false }
        
        let httpEnabled = (proxies[kCFNetworkProxiesHTTPEnable as String] as? Int) == 1
        let httpsEnabled = (proxies[kCFNetworkProxiesHTTPSEnable as String] as? Int) == 1
        let socksEnabled = (proxies[kCFNetworkProxiesSOCKSEnable as String] as? Int) == 1
        
        return httpEnabled || httpsEnabled || socksEnabled
    }
    
    // MARK: - Private Methods
    
    private func saveOriginalSettings() {
        guard let proxies = getSystemProxies() else { return }
        originalProxySettings = proxies
        print("💾 已保存原始代理设置")
    }
    
    private func setSystemProxy(enabled: Bool) throws {
        guard let primaryService = getPrimaryNetworkService() else {
            throw SystemProxyError.networkServiceNotFound
        }
        
        let proxySettings: [String: Any] = enabled ? [
            kCFNetworkProxiesHTTPEnable as String: 1,
            kCFNetworkProxiesHTTPProxy as String: proxyHost,
            kCFNetworkProxiesHTTPPort as String: httpPort,
            
            kCFNetworkProxiesHTTPSEnable as String: 1,
            kCFNetworkProxiesHTTPSProxy as String: proxyHost,
            kCFNetworkProxiesHTTPSPort as String: httpPort,
            
            kCFNetworkProxiesSOCKSEnable as String: 1,
            kCFNetworkProxiesSOCKSProxy as String: proxyHost,
            kCFNetworkProxiesSOCKSPort as String: socksPort,
            
            // 排除本地地址
            kCFNetworkProxiesExceptionsList as String: [
                "localhost",
                "127.0.0.1",
                "*.local",
                "192.168.0.0/16",
                "10.0.0.0/8"
            ]
        ] : (enabled ? [:] : originalProxySettings)
        
        // 创建动态存储引用
        guard let dynamicStore = SCDynamicStoreCreate(
            nil,
            "Phase" as CFString,
            nil,
            nil
        ) else {
            throw SystemProxyError.dynamicStoreCreateFailed
        }
        
        // 设置代理
        let key = "State:/Network/Global/Proxies" as CFString
        let success = SCDynamicStoreSetValue(dynamicStore, key, proxySettings as CFDictionary)
        
        guard success else {
            throw SystemProxyError.setProxyFailed
        }
        
        // 应用更改
        applyProxyChanges(to: primaryService, settings: proxySettings)
    }
    
    private func applyProxyChanges(to serviceID: String, settings: [String: Any]) {
        // 使用 networksetup 命令需要管理员权限
        // 这里仅作为备选方案，实际使用 SystemConfiguration API
        print("⚠️ 系统代理设置可能需要管理员权限")
        
        // 可选：使用 AppleScript 或 networksetup 命令
        // 需要用户授权
    }
    
    private func getPrimaryNetworkService() -> String? {
        guard let dynamicStore = SCDynamicStoreCreate(
            nil,
            "Phase" as CFString,
            nil,
            nil
        ) else {
            return nil
        }
        
        let key = "State:/Network/Global/IPv4" as CFString
        guard let globalIPv4 = SCDynamicStoreCopyValue(dynamicStore, key) as? [String: Any],
              let primaryService = globalIPv4["PrimaryService"] as? String else {
            return nil
        }
        
        return primaryService
    }
    
    private func getSystemProxies() -> [String: Any]? {
        guard let dynamicStore = SCDynamicStoreCreate(
            nil,
            "Phase" as CFString,
            nil,
            nil
        ) else {
            return nil
        }
        
        let key = "State:/Network/Global/Proxies" as CFString
        guard let proxies = SCDynamicStoreCopyValue(dynamicStore, key) as? [String: Any] else {
            return [:]
        }
        
        return proxies
    }
}

// MARK: - Alternative Implementation (Using networksetup)

extension SystemProxyManager {
    /// 使用 networksetup 命令行工具设置代理（需要管理员权限）
    func setProxyUsingNetworkSetup(enabled: Bool) throws {
        let networkService = "Wi-Fi" // 可以动态获取
        
        if enabled {
            // 启用代理
            try runNetworkSetup(["-setwebproxy", networkService, proxyHost, "\(httpPort)"])
            try runNetworkSetup(["-setsecurewebproxy", networkService, proxyHost, "\(httpPort)"])
            try runNetworkSetup(["-setsocksfirewallproxy", networkService, proxyHost, "\(socksPort)"])
            
            // 启用代理开关
            try runNetworkSetup(["-setwebproxystate", networkService, "on"])
            try runNetworkSetup(["-setsecurewebproxystate", networkService, "on"])
            try runNetworkSetup(["-setsocksfirewallproxystate", networkService, "on"])
        } else {
            // 禁用代理
            try runNetworkSetup(["-setwebproxystate", networkService, "off"])
            try runNetworkSetup(["-setsecurewebproxystate", networkService, "off"])
            try runNetworkSetup(["-setsocksfirewallproxystate", networkService, "off"])
        }
    }
    
    private func runNetworkSetup(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw SystemProxyError.networkSetupFailed(output)
        }
    }
    
    /// 获取活动的网络服务名称
    func getActiveNetworkService() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = ["-listallhardwareports"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            
            // 解析输出获取活动的服务
            // 通常是 Wi-Fi 或 Ethernet
            if output.contains("Wi-Fi") {
                return "Wi-Fi"
            } else if output.contains("Ethernet") {
                return "Ethernet"
            }
        } catch {
            print("❌ 获取网络服务失败: \(error)")
        }
        
        return nil
    }
}

// MARK: - Error Types

enum SystemProxyError: Error, LocalizedError {
    case networkServiceNotFound
    case dynamicStoreCreateFailed
    case setProxyFailed
    case networkSetupFailed(String)
    case authorizationRequired
    
    var errorDescription: String? {
        switch self {
        case .networkServiceNotFound:
            return "未找到主要网络服务"
        case .dynamicStoreCreateFailed:
            return "创建系统配置存储失败"
        case .setProxyFailed:
            return "设置代理失败"
        case .networkSetupFailed(let output):
            return "networksetup 命令失败: \(output)"
        case .authorizationRequired:
            return "需要管理员权限"
        }
    }
}

// MARK: - Helper Extension

extension SystemProxyManager {
    /// 打印当前系统代理状态（用于调试）
    func printCurrentProxySettings() {
        guard let proxies = getSystemProxies() else {
            print("❌ 无法获取系统代理设置")
            return
        }
        
        print("📋 当前系统代理设置:")
        print("  HTTP 代理: \(proxies[kCFNetworkProxiesHTTPEnable as String] as? Int == 1 ? "已启用" : "已禁用")")
        if let host = proxies[kCFNetworkProxiesHTTPProxy as String] as? String,
           let port = proxies[kCFNetworkProxiesHTTPPort as String] as? Int {
            print("    地址: \(host):\(port)")
        }
        
        print("  HTTPS 代理: \(proxies[kCFNetworkProxiesHTTPSEnable as String] as? Int == 1 ? "已启用" : "已禁用")")
        if let host = proxies[kCFNetworkProxiesHTTPSProxy as String] as? String,
           let port = proxies[kCFNetworkProxiesHTTPSPort as String] as? Int {
            print("    地址: \(host):\(port)")
        }
        
        print("  SOCKS 代理: \(proxies[kCFNetworkProxiesSOCKSEnable as String] as? Int == 1 ? "已启用" : "已禁用")")
        if let host = proxies[kCFNetworkProxiesSOCKSProxy as String] as? String,
           let port = proxies[kCFNetworkProxiesSOCKSPort as String] as? Int {
            print("    地址: \(host):\(port)")
        }
    }
}
