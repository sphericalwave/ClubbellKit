import Foundation

/// Pure geometric description of a clubbell, in imperial units (inches, pounds).
///
/// Layout, bottom (x = 0) to top (x = totalLength), all measured in inches:
///   • knob   – a sphere of `ballDiameter`, resting with its bottom at x = 0
///   • grip   – a cylinder of `gripDiameter`, x ∈ [ballDiameter/2, gripEnd]
///              (starts at the knob centre; the knob caps the bottom end).
///              `gripLength` is the *bare* handle as measured on a real club,
///              from where it leaves the knob (`knobLength`) to the taper, so
///              gripEnd = knobLength + gripLength.
///   • taper  – a frustum, gripDiameter → barrelDiameter over `taperLength`
///   • barrel – a cylinder of `barrelDiameter`, length `barrelLength`
///
/// The body is the *union* of these coaxial solids, so the radius at any x is
/// the largest contributing radius (the knob bulges out of the bottom of the
/// grip; nothing is ever double-counted).
public struct ClubDimensions: Codable, Hashable, Sendable {
    public var ballDiameter:   Double   // in  – pommel / knob at the end of the handle
    public var gripDiameter:   Double   // in  – the straight handle you hold
    public var gripLength:     Double   // in  – bare straight handle, knob face → taper
    public var taperLength:    Double   // in  – transition handle → barrel ("tapering distance")
    public var barrelDiameter: Double   // in  – the heavy head
    public var barrelLength:   Double   // in
    public var weightLb:       Double   // lb  – target total weight (sets effective density)

    public init(ballDiameter: Double, gripDiameter: Double, gripLength: Double,
                taperLength: Double, barrelDiameter: Double, barrelLength: Double,
                weightLb: Double) {
        self.ballDiameter = ballDiameter
        self.gripDiameter = gripDiameter
        self.gripLength = gripLength
        self.taperLength = taperLength
        self.barrelDiameter = barrelDiameter
        self.barrelLength = barrelLength
        self.weightLb = weightLb
    }

    /// Where the bare handle leaves the knob: the flat face cut into the ball
    /// where its chord equals the grip diameter (inches from the knob end).
    public var knobLength: Double {
        let rk = ballDiameter / 2, rg = gripDiameter / 2
        return rk > rg ? rk + (rk * rk - rg * rg).squareRoot() : ballDiameter
    }

    /// End of the straight handle / start of the taper.
    public var gripEnd: Double { knobLength + gripLength }

    public var totalLength: Double { gripEnd + taperLength + barrelLength }

    /// Outer radius (inches) of the solid of revolution at axial position x (inches).
    ///
    /// `includeKnob` is a drawing-only escape hatch: the profile view renders the
    /// knob as a separate sphere, so it asks for the body radius without it.
    public func radius(atX x: Double, includeKnob: Bool = true) -> Double {
        guard x >= 0, x <= totalLength else { return 0 }
        let rk = ballDiameter / 2
        let rg = gripDiameter / 2
        let rb = barrelDiameter / 2
        var r = 0.0

        // Knob: sphere centred at x = rk
        if includeKnob, x <= ballDiameter {
            let v = rk * rk - (x - rk) * (x - rk)
            if v > 0 { r = max(r, v.squareRoot()) }
        }
        // Grip cylinder — starts at the knob centre, so the knob caps the end of
        // the shaft (no rod pokes out past the ball, in the drawing or the maths).
        if x >= rk, x <= gripEnd { r = max(r, rg) }
        // Taper frustum
        let taperStart = gripEnd
        let taperEnd   = gripEnd + taperLength
        if x >= taperStart, x <= taperEnd, taperLength > 0 {
            let t = (x - taperStart) / taperLength
            r = max(r, rg + t * (rb - rg))
        }
        // Barrel cylinder
        if x >= taperEnd, x <= totalLength { r = max(r, rb) }

        return r
    }

    /// Sampled silhouette (x, radius) pairs in inches, for drawing.
    public func silhouette(samples: Int = 160, includeKnob: Bool = true) -> [(x: Double, r: Double)] {
        let L = totalLength
        guard L > 0, samples > 1 else { return [] }
        return (0...samples).map { i in
            let x = L * Double(i) / Double(samples)
            return (x, radius(atX: x, includeKnob: includeKnob))
        }
    }

    /// A sensible default ~15 lb club to seed new entries.
    public static let sample = ClubDimensions(
        ballDiameter: 2.0, gripDiameter: 1.25, gripLength: 6.0,
        taperLength: 4.0, barrelDiameter: 3.0, barrelLength: 6.0, weightLb: 15.0
    )
}
