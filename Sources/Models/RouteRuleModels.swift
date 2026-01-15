import Foundation

/// 路由规则模型
struct RouteRule: Identifiable, Codable {
    let id: UUID
    let name: String
    let type: RuleType
    let action: RuleAction
    var patterns: [String]
    var isEnabled: Bool
    
    enum RuleType: String, Codable, CaseIterable {
        case domain = "域名"
        case domainSuffix = "域名后缀"
        case domainKeyword = "域名关键词"
        case ipCidr = "IP-CIDR"
        case geoip = "GeoIP"
        case geosite = "GeoSite"
        
        var iconName: String {
            switch self {
            case .domain, .domainSuffix, .domainKeyword:
                return "globe"
            case .ipCidr:
                return "network"
            case .geoip:
                return "location.fill"
            case .geosite:
                return "mappin.and.ellipse"
            }
        }
    }
    
    enum RuleAction: String, Codable, CaseIterable {
        case proxy = "代理"
        case direct = "直连"
        case reject = "拒绝"
        
        var color: String {
            switch self {
            case .proxy: return "blue"
            case .direct: return "green"
            case .reject: return "red"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        type: RuleType,
        action: RuleAction,
        patterns: [String],
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.action = action
        self.patterns = patterns
        self.isEnabled = isEnabled
    }
}

/// 规则组
struct RuleGroup: Identifiable {
    let id: UUID
    let name: String
    let action: RouteRule.RuleAction
    var rules: [RouteRule]
    
    init(
        id: UUID = UUID(),
        name: String,
        action: RouteRule.RuleAction,
        rules: [RouteRule] = []
    ) {
        self.id = id
        self.name = name
        self.action = action
        self.rules = rules
    }
}
