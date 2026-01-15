import Foundation

/// 订阅模型
struct Subscription: Identifiable, Codable {
  let id: UUID
  var name: String
  var url: String
  var updateInterval: Int  // 小时
  var lastUpdate: Date?
  var nodeCount: Int
  var isEnabled: Bool

  init(
    id: UUID = UUID(),
    name: String,
    url: String,
    updateInterval: Int = 24,
    lastUpdate: Date? = nil,
    nodeCount: Int = 0,
    isEnabled: Bool = true
  ) {
    self.id = id
    self.name = name
    self.url = url
    self.updateInterval = updateInterval
    self.lastUpdate = lastUpdate
    self.nodeCount = nodeCount
    self.isEnabled = isEnabled
  }

  var needsUpdate: Bool {
    guard let lastUpdate = lastUpdate else { return true }
    let interval = TimeInterval(updateInterval * 3600)
    return Date().timeIntervalSince(lastUpdate) > interval
  }

  var lastUpdateFormatted: String {
    guard let lastUpdate = lastUpdate else { return "从未更新" }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: lastUpdate, relativeTo: Date())
  }
}
