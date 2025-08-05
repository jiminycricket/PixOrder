import Foundation
import CoreGraphics

public struct AspectRatio: Equatable, CustomStringConvertible, Sendable {
    public let ratio: Double
    public let tolerance: Double
    
    public init(ratio: Double, tolerance: Double = 0.05) {
        self.ratio = ratio
        self.tolerance = tolerance
    }
    
    public init(width: CGFloat, height: CGFloat, tolerance: Double = 0.05) {
        self.ratio = Double(width / height)
        self.tolerance = tolerance
    }
    
    public var description: String {
        // Convert to simple fraction representation for common ratios
        let commonRatios: [(Double, String)] = [
            (1.0, "1:1"),
            (1.333, "4:3"),
            (1.5, "3:2"),
            (1.777, "16:9"),
            (2.333, "21:9"),
            (0.75, "3:4"),
            (0.667, "2:3"),
            (0.562, "9:16")
        ]
        
        for (commonRatio, description) in commonRatios {
            if matches(commonRatio, tolerance: 0.05) {
                return description
            }
        }
        
        return String(format: "%.3f:1", ratio)
    }
    
    public func matches(_ otherRatio: Double, tolerance: Double? = nil) -> Bool {
        let actualTolerance = tolerance ?? self.tolerance
        return abs(ratio - otherRatio) <= actualTolerance
    }
    
    public func matches(_ other: AspectRatio) -> Bool {
        return matches(other.ratio, tolerance: max(tolerance, other.tolerance))
    }
}

public struct RatioCalculator {
    public init() {}
    
    public func calculateRatio(from dimensions: MediaDimensions) -> AspectRatio {
        return AspectRatio(width: dimensions.width, height: dimensions.height)
    }
    
    public func calculateRatio(width: CGFloat, height: CGFloat) -> AspectRatio {
        return AspectRatio(width: width, height: height)
    }
    
    public static let commonRatios: [String: AspectRatio] = [
        "square": AspectRatio(ratio: 1.0),
        "4:3": AspectRatio(ratio: 4.0/3.0),
        "3:2": AspectRatio(ratio: 3.0/2.0),
        "16:9": AspectRatio(ratio: 16.0/9.0),
        "21:9": AspectRatio(ratio: 21.0/9.0),
        "portrait_4:3": AspectRatio(ratio: 3.0/4.0),
        "portrait_3:2": AspectRatio(ratio: 2.0/3.0),
        "portrait_9:16": AspectRatio(ratio: 9.0/16.0)
    ]
}