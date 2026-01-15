import Foundation
import Combine

/// 代理管理器 - 单例
/// 负责管理代理状态、节点选择和流量统计
@MainActor
class ProxyManager: ObservableObject {
    static let shared = ProxyManager()
    
    @Published var isRunning: Bool = false
    @Published var selectedNode: ProxyNode?
    @Published var nodes: [ProxyNode] = []
    @Published var trafficStats: TrafficStats = TrafficStats(uploadBytes: 0, downloadBytes: 0)
    @Published var isSystemProxyEnabled: Bool = false
    
    // 累计流量（避免显示 0 KB）
    private var accumulatedUpload: Int64 = 1024 * 100  // 初始 100 KB
    private var accumulatedDownload: Int64 = 1024 * 500  // 初始 500 KB
    
    private let configManager = ConfigManager()
    private let singBoxService = SingBoxService.shared
    private let systemProxyManager = SystemProxyManager.shared
    private var trafficTimer: Timer?
    
    private init() {
        loadConfig()
        setupMockData()
    }
    
    // MARK: - Public Methods
    
    func toggleProxy() {
        isRunning.toggle()
        
        if isRunning {
            startProxy()
        } else {
            stopProxy()
        }
    }
    
    func selectNode(_ node: ProxyNode) {
        selectedNode = node
        
        if isRunning {
            // 重启代理以应用新节点
            stopProxy()
            startProxy()
        }
    }
    
    func testNodeLatency(_ node: ProxyNode) async -> Int {
        // TODO: 实现真实的延迟测试
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        return Int.random(in: 30...500)
    }
    
    func testAllNodesLatency() async {
        await withTaskGroup(of: (UUID, Int).self) { group in
            for node in nodes {
                group.addTask {
                    let latency = await self.testNodeLatency(node)
                    return (node.id, latency)
                }
            }
            
            for await (nodeId, latency) in group {
                if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
                    nodes[index].latency = latency
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startProxy() {
        print("🚀 Starting proxy with node: \(selectedNode?.name ?? "None")")
        
        // 生成 sing-box 配置
        let config = SingBoxConfig.createDefault(node: selectedNode)
        
        // 启动 sing-box
        do {
            try singBoxService.start(config: config)
            
            // 启用系统代理
            do {
                try systemProxyManager.enableProxy()
                isSystemProxyEnabled = true
            } catch {
                print("⚠️ 启用系统代理失败: \(error.localizedDescription)")
                // 系统代理失败不影响 sing-box 运行
            }
            
            // 启动流量统计
            startTrafficMonitoring()
        } catch {
            print("❌ Failed to start sing-box: \(error)")
            isRunning = false
        }
    }
    
    private func stopProxy() {
        print("⏹️ Stopping proxy")
        
        // 禁用系统代理
        do {
            try systemProxyManager.disableProxy()
            isSystemProxyEnabled = false
        } catch {
            print("⚠️ 禁用系统代理失败: \(error.localizedDescription)")
        }
        
        // 停止 sing-box
        singBoxService.stop()
        
        // 停止流量统计
        stopTrafficMonitoring()
    }
    
    private func startTrafficMonitoring() {
        // 初始化累计流量
        trafficStats.uploadBytes = accumulatedUpload
        trafficStats.downloadBytes = accumulatedDownload
        
        trafficTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // TODO: 从 sing-box 获取真实流量数据
                let uploadDelta = Int64.random(in: 1000...50000)
                let downloadDelta = Int64.random(in: 5000...200000)
                
                self.accumulatedUpload += uploadDelta
                self.accumulatedDownload += downloadDelta
                
                self.trafficStats.uploadBytes = self.accumulatedUpload
                self.trafficStats.downloadBytes = self.accumulatedDownload
            }
        }
    }
    
    private func stopTrafficMonitoring() {
        trafficTimer?.invalidate()
        trafficTimer = nil
        
        // 保存累计流量
        accumulatedUpload = trafficStats.uploadBytes
        accumulatedDownload = trafficStats.downloadBytes
    }
    
    private func loadConfig() {
        if let config = configManager.loadConfig() {
            self.nodes = config.nodes
            if let selectedId = config.selectedNodeId {
                self.selectedNode = config.nodes.first { $0.id == selectedId }
            }
        }
    }
    
    private func saveConfig() {
        let config = ProxyConfig(
            selectedNodeId: selectedNode?.id,
            isSystemProxyEnabled: isRunning,
            nodes: nodes
        )
        configManager.saveConfig(config)
    }
    
    // MARK: - Mock Data
    
    private func setupMockData() {
        guard nodes.isEmpty else { return }
        
        nodes = [
            ProxyNode(name: "香港 01", type: .shadowsocks, server: "hk01.example.com", port: 8388, latency: 45),
            ProxyNode(name: "香港 02", type: .vmess, server: "hk02.example.com", port: 443, latency: 52),
            ProxyNode(name: "新加坡 01", type: .trojan, server: "sg01.example.com", port: 443, latency: 78),
            ProxyNode(name: "新加坡 02", type: .hysteria2, server: "sg02.example.com", port: 36712, latency: 82),
            ProxyNode(name: "日本 01", type: .vless, server: "jp01.example.com", port: 443, latency: 95),
            ProxyNode(name: "美国 01", type: .shadowsocks, server: "us01.example.com", port: 8388, latency: 180),
            ProxyNode(name: "美国 02", type: .vmess, server: "us02.example.com", port: 443, latency: 195),
        ]
        
        selectedNode = nodes.first
    }
}

/// 配置管理器
/// 负责配置的持久化存储
class ConfigManager {
    private let configFileName = "phase-config.json"
    
    private var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let phaseDir = appSupport.appendingPathComponent("Phase", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: phaseDir, withIntermediateDirectories: true)
        
        return phaseDir.appendingPathComponent(configFileName)
    }
    
    func loadConfig() -> ProxyConfig? {
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        return try? JSONDecoder().decode(ProxyConfig.self, from: data)
    }
    
    func saveConfig(_ config: ProxyConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configURL)
    }
}
