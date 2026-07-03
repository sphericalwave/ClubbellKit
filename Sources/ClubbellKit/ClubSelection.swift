import Foundation

/// A chosen clubbell and how it's gripped — the value a host app persists
/// (e.g. attached to a progYog skill to scale its challenge).
///
/// Codable and SwiftData-free on purpose: store it however the host likes
/// (its own `@Model`, JSON, `@AppStorage`, …).
public struct ClubSelection: Codable, Hashable, Sendable {
    public var dimensions: ClubDimensions
    public var gripCenterIn: Double
    public var handWidthIn: Double
    /// Centre of a second (upper) hand for a two-handed grip. `nil` = one hand.
    /// Optional so existing single-grip JSON decodes unchanged.
    public var secondGripCenterIn: Double?

    public init(dimensions: ClubDimensions = .sample,
                gripCenterIn: Double = 3.0,
                handWidthIn: Double = 4.0,
                secondGripCenterIn: Double? = nil) {
        self.dimensions = dimensions
        self.gripCenterIn = gripCenterIn
        self.handWidthIn = handWidthIn
        self.secondGripCenterIn = secondGripCenterIn
    }
}

public extension ClubSelection {
    /// Lowest grip centre that keeps the whole hand off the knob.
    var gripLowerBound: Double { dimensions.ballDiameter + handWidthIn / 2 }

    /// Highest grip centre that keeps the whole hand on the club.
    var gripUpperBound: Double { max(dimensions.totalLength - handWidthIn / 2, gripLowerBound) }

    /// Whether a second (upper) hand is placed.
    var isTwoHanded: Bool { secondGripCenterIn != nil }

    /// Add a second hand stacked just above the first (clamped to the shaft).
    mutating func enableSecondGrip() {
        guard secondGripCenterIn == nil else { return }
        secondGripCenterIn = min(gripCenterIn + handWidthIn, gripUpperBound)
        clampGrip()
    }

    mutating func disableSecondGrip() { secondGripCenterIn = nil }

    /// Clamp both hands so they stay on the shaft (off the knob).
    mutating func clampGrip() {
        gripCenterIn = min(max(gripCenterIn, gripLowerBound), gripUpperBound)
        if let s = secondGripCenterIn {
            secondGripCenterIn = min(max(s, gripLowerBound), gripUpperBound)
        }
    }

    /// Mechanics for this selection at a given pose.
    func mechanics(angleFromVerticalDeg: Double = 90, rpm: Double = 0) -> MechanicsResult {
        ClubMechanics.compute(dims: dimensions, gripCenterIn: gripCenterIn,
                              angleFromVerticalDeg: angleFromVerticalDeg, rpm: rpm)
    }
}
