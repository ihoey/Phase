import Combine
import Foundation

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
    @Published var subscriptionNodes: [UUID: [ProxyNode]] = [:]  // 订阅ID -> 节点列表
    @Published var proxyMode: ProxyMode = .rule  // 代理模式
    @Published var startTime: Date?  // 代理启动时间

    // 流量历史数据（用于图表）
    @Published var uploadSpeedHistory: [TrafficDataPoint] = []
    @Published var downloadSpeedHistory: [TrafficDataPoint] = []
    private let maxHistoryPoints = 60  // 保留60个数据点（1分钟）
    private var lastTrafficStats: TrafficStats?
    private var lastTrafficUpdateTime: Date?

    private let configManager = ConfigManager()
    private let singBoxService = SingBoxService.shared
    private let systemProxyManager = SystemProxyManager.shared
    private var trafficTimer: Timer?

    private init() {
        loadConfig()
        setupMockData()
    }

    /// 切换代理模式
    func switchMode(_ mode: ProxyMode) {
        guard proxyMode != mode else { return }

        proxyMode = mode
        saveConfig()

        // 如果代理正在运行，重启以应用新模式
        if isRunning {
            stopProxy()
            startProxy()
        }
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

    /// 测试特定订阅的节点延迟
    func testSubscriptionNodesLatency(_ subscriptionId: UUID) async {
        guard let nodeList = subscriptionNodes[subscriptionId] else { return }
        
        await withTaskGroup(of: (UUID, Int).self) { group in
            for node in nodeList {
                group.addTask {
                    let latency = await self.testNodeLatency(node)
                    return (node.id, latency)
                }
            }

            for await (nodeId, latency) in group {
                // 更新订阅节点列表中的延迟
                if var nodes = subscriptionNodes[subscriptionId],
                   let index = nodes.firstIndex(where: { $0.id == nodeId }) {
                    nodes[index].latency = latency
                    subscriptionNodes[subscriptionId] = nodes
                }
                // 同时更新总节点列表
                if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
                    nodes[index].latency = latency
                }
            }
        }
    }

    // MARK: - Private Methods

    private func startProxy() {
        print(
            "🚀 Starting proxy with node: \(selectedNode?.name ?? "None"), mode: \(proxyMode.rawValue)"
        )

        // 根据代理模式和节点生成配置
        let config = SingBoxConfig.createDefault(node: selectedNode, mode: proxyMode)

        // 启动 sing-box
        do {
            try singBoxService.start(config: config)

            self.startTime = Date()

            // 启动流量统计
            startTrafficMonitoring()
        } catch {
            print("❌ Failed to start sing-box: \(error)")
            isRunning = false
        }
    }

    private func stopProxy() {
        print("⏹️ Stopping proxy")

        // 停止 sing-box
        singBoxService.stop()

        self.startTime = nil

        // 停止流量统计
        stopTrafficMonitoring()
    }

    /// 启用系统代理
    func enableSystemProxy() {
        guard isRunning else {
            print("⚠️ 代理未运行，无法启用系统代理")
            return
        }

        print("🔧 尝试启用系统代理...")
        do {
            try systemProxyManager.enableProxy()
            isSystemProxyEnabled = true
            print("✅ 系统代理已启用")
        } catch {
            print("❌ 启用系统代理失败: \(error.localizedDescription)")
            isSystemProxyEnabled = false
        }
    }

    /// 禁用系统代理
    func disableSystemProxy() {
        print("🔧 尝试禁用系统代理...")
        do {
            try systemProxyManager.disableProxy()
            isSystemProxyEnabled = false
            print("✅ 系统代理已禁用")
        } catch {
            print("❌ 禁用系统代理失败: \(error.localizedDescription)")
            isSystemProxyEnabled = false
        }
    }

    /// 切换系统代理状态
    func toggleSystemProxy() {
        if isSystemProxyEnabled {
            disableSystemProxy()
        } else {
            enableSystemProxy()
        }
    }

    private func startTrafficMonitoring() {
        lastTrafficStats = trafficStats
        lastTrafficUpdateTime = Date()
        uploadSpeedHistory.removeAll()
        downloadSpeedHistory.removeAll()

        trafficTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                // TODO: 从 sing-box 获取真实流量数据
                let newUpload = Int64.random(in: 1000...50000)
                let newDownload = Int64.random(in: 5000...200000)

                self.trafficStats.uploadBytes += newUpload
                self.trafficStats.downloadBytes += newDownload

                // 计算速率并添加到历史记录
                let now = Date()
                self.uploadSpeedHistory.append(
                    TrafficDataPoint(
                        timestamp: now,
                        value: Double(newUpload)
                    ))
                self.downloadSpeedHistory.append(
                    TrafficDataPoint(
                        timestamp: now,
                        value: Double(newDownload)
                    ))

                // 保持历史记录在指定大小
                if self.uploadSpeedHistory.count > self.maxHistoryPoints {
                    self.uploadSpeedHistory.removeFirst()
                }
                if self.downloadSpeedHistory.count > self.maxHistoryPoints {
                    self.downloadSpeedHistory.removeFirst()
                }
            }
        }
    }

    private func stopTrafficMonitoring() {
        trafficTimer?.invalidate()
        trafficTimer = nil
        uploadSpeedHistory.removeAll()
        downloadSpeedHistory.removeAll()
    }

    private func loadConfig() {
        if let config = configManager.loadConfig() {
            // 加载保存的配置
            if let nodeId = config.selectedNodeId,
                let node = nodes.first(where: { $0.id == nodeId })
            {
                selectedNode = node
            }
            proxyMode = config.proxyMode ?? .rule
        }
    }

    private func saveConfig() {
        let config = ProxyConfig(
            selectedNodeId: selectedNode?.id,
            proxyMode: proxyMode
        )
        configManager.saveConfig(config)
    }

    // MARK: - Mock Data

    private func setupMockData() {
        guard nodes.isEmpty else { return }

        nodes = [
            ProxyNode(
                name: "香港 01", type: .shadowsocks, server: "hk01.example.com", port: 8388,
                latency: 45),
            ProxyNode(
                name: "香港 02", type: .vmess, server: "hk02.example.com", port: 443, latency: 52),
            ProxyNode(
                name: "新加坡 01", type: .trojan, server: "sg01.example.com", port: 443, latency: 78),
            ProxyNode(
                name: "新加坡 02", type: .hysteria2, server: "sg02.example.com", port: 36712,
                latency: 82),
            ProxyNode(
                name: "日本 01", type: .vless, server: "jp01.example.com", port: 443, latency: 95),
            ProxyNode(
                name: "美国 01", type: .shadowsocks, server: "us01.example.com", port: 8388,
                latency: 180),
            ProxyNode(
                name: "美国 02", type: .vmess, server: "us02.example.com", port: 443, latency: 195),
        ]

        selectedNode = nodes.first
    }

    // MARK: - Subscription Management

    /// 添加订阅节点
    func addSubscriptionNodes(_ subscriptionId: UUID, nodes: [ProxyNode]) {
        subscriptionNodes[subscriptionId] = nodes
        updateAllNodes()
    }

    /// 移除订阅节点
    func removeSubscriptionNodes(_ subscriptionId: UUID) {
        subscriptionNodes.removeValue(forKey: subscriptionId)
        updateAllNodes()
    }

    /// 更新总节点列表
    private func updateAllNodes() {
        var allNodes: [ProxyNode] = []

        // 添加所有订阅的节点
        for nodeList in subscriptionNodes.values {
            allNodes.append(contentsOf: nodeList)
        }

        // 如果没有订阅节点，使用模拟数据
        if allNodes.isEmpty {
            setupMockData()
        } else {
            nodes = allNodes
            if selectedNode == nil || !nodes.contains(where: { $0.id == selectedNode?.id }) {
                selectedNode = nodes.first
            }
        }
    }
}

/// 配置管理器
/// 负责配置的持久化存储
class ConfigManager {
    private let configFileName = "phase-config.json"

    private var configURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
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
