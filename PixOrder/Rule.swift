import Foundation

public struct Rule: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let targetRatio: AspectRatio
    public let destinationPath: String
    public let isEnabled: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        targetRatio: AspectRatio,
        destinationPath: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.targetRatio = targetRatio
        self.destinationPath = destinationPath
        self.isEnabled = isEnabled
    }
    
    public func matches(_ aspectRatio: AspectRatio) -> Bool {
        guard isEnabled else { return false }
        return targetRatio.matches(aspectRatio)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, destinationPath, isEnabled
        case targetRatioValue = "targetRatio"
        case targetRatioTolerance = "tolerance"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        destinationPath = try container.decode(String.self, forKey: .destinationPath)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        
        let ratioValue = try container.decode(Double.self, forKey: .targetRatioValue)
        let tolerance = try container.decodeIfPresent(Double.self, forKey: .targetRatioTolerance) ?? 0.05
        targetRatio = AspectRatio(ratio: ratioValue, tolerance: tolerance)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(destinationPath, forKey: .destinationPath)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(targetRatio.ratio, forKey: .targetRatioValue)
        try container.encode(targetRatio.tolerance, forKey: .targetRatioTolerance)
    }
}

public struct RuleSet: Codable {
    public var rules: [Rule]
    
    public init(rules: [Rule] = []) {
        self.rules = rules
    }
    
    public func findMatchingRule(for aspectRatio: AspectRatio) -> Rule? {
        return rules.first { $0.matches(aspectRatio) }
    }
    
    public static let defaultRules: [Rule] = [
        Rule(name: "Square (1:1)", targetRatio: RatioCalculator.commonRatios["square"]!, destinationPath: "Square"),
        Rule(name: "Landscape 16:9", targetRatio: RatioCalculator.commonRatios["16:9"]!, destinationPath: "Landscape_16-9"),
        Rule(name: "Landscape 4:3", targetRatio: RatioCalculator.commonRatios["4:3"]!, destinationPath: "Landscape_4-3"),
        Rule(name: "Portrait 9:16", targetRatio: RatioCalculator.commonRatios["portrait_9:16"]!, destinationPath: "Portrait_9-16"),
        Rule(name: "Portrait 3:4", targetRatio: RatioCalculator.commonRatios["portrait_4:3"]!, destinationPath: "Portrait_3-4")
    ]
}