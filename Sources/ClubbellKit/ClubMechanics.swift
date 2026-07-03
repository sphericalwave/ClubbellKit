import Foundation

/// Everything the model computes for a given club + grip + pose, in display units.
public struct MechanicsResult: Sendable {
    // Static / mass distribution
    public var weightLb: Double
    public var comFromBottomIn: Double          // centre of mass, inches from the knob end
    public var leverArmIn: Double               // signed grip → CoM distance (+ toward barrel)

    // Gravitational ("leverage you feel") torque about the grip
    public var torqueLbFt: Double
    public var torqueLbIn: Double
    public var maxTorqueLbFt: Double            // at horizontal (θ = 90°), for reference

    // Moments of inertia
    public var iTransverseLbIn2: Double         // about the grip, swing/lever axis (mass moment)
    public var iTransverseSlugFt2: Double
    public var iAxialLbIn2: Double              // about the club's own long axis (spinning)

    // Dynamics
    public var angularMomentumSlugFt2PerS: Double   // L = I_transverse · ω

    // Informational: the uniform-density assumption
    public var effectiveDensityKgM3: Double
    public var solidSteelWeightLb: Double       // what the geometry would weigh as solid steel
}

public extension MechanicsResult {
    private func omega(_ rpm: Double) -> Double { rpm * 2 * .pi / 60 }   // rad/s

    /// Gravitational ("leverage") torque (lb·ft) at a given club angle from vertical.
    /// Independent of speed: τ = W · lever · sin θ.
    func gravityTorqueLbFt(angleFromVerticalDeg deg: Double) -> Double {
        abs(weightLb * leverArmIn / 12.0) * sin(deg * .pi / 180)
    }

    /// Torque (lb·ft) to snap the swing from +ω to −ω within `turnaroundSec`.
    /// τ = I · (2ω / Δt). Linear in ω. This is the "stop and reverse" cost at the
    /// ends of an arc — the dominant *driving* torque a swing demands.
    func reversalTorqueLbFt(rpm: Double, turnaroundSec: Double) -> Double {
        guard turnaroundSec > 0 else { return 0 }
        return iTransverseSlugFt2 * (2 * omega(rpm) / turnaroundSec)
    }

    /// Angular momentum about the wrist (slug·ft²/s). What you must absorb to stop it.
    func angularMomentum(rpm: Double) -> Double { iTransverseSlugFt2 * omega(rpm) }

    /// Rotational kinetic energy (ft·lb). Scales with ω².
    func kineticEnergyFtLb(rpm: Double) -> Double {
        0.5 * iTransverseSlugFt2 * pow(omega(rpm), 2)
    }

    /// Centripetal grip force (lb) pulling the club outward along its axis.
    /// F = m · ω² · r. Scales with ω² — what rips a club loose at speed.
    func centripetalForceLb(rpm: Double) -> Double {
        let massSlug = weightLb / Units.gFtPerS2
        let rFt = abs(leverArmIn) / 12.0
        return massSlug * pow(omega(rpm), 2) * rFt
    }
}

public enum ClubMechanics {

    /// Compute the full mechanical picture.
    /// - Parameters:
    ///   - dims: club geometry + target weight (imperial)
    ///   - gripCenterIn: axial position of the centre of the hand, inches from the knob
    ///   - angleFromVerticalDeg: club-axis tilt. 0° = hanging straight down (no gravity
    ///       torque), 90° = held horizontal (maximum torque)
    ///   - rpm: swing rate about the wrist, revolutions per minute
    ///   - slices: integration resolution
    public static func compute(dims: ClubDimensions,
                               gripCenterIn: Double,
                               angleFromVerticalDeg: Double,
                               rpm: Double,
                               slices: Int = 4000) -> MechanicsResult {

        let L = dims.totalLength
        guard L > 0, slices > 0 else {
            return MechanicsResult(weightLb: dims.weightLb, comFromBottomIn: 0, leverArmIn: 0,
                                   torqueLbFt: 0, torqueLbIn: 0, maxTorqueLbFt: 0,
                                   iTransverseLbIn2: 0, iTransverseSlugFt2: 0, iAxialLbIn2: 0,
                                   angularMomentumSlugFt2PerS: 0,
                                   effectiveDensityKgM3: 0, solidSteelWeightLb: 0)
        }

        let dxIn = L / Double(slices)
        let dxM  = dxIn * Units.inToM
        let pivotM = gripCenterIn * Units.inToM

        // Pass 1: volume (m³) and first moment, with unit density.
        var volume = 0.0        // m³  (∫ π r² dx)
        var firstMoment = 0.0   // m⁴  (∫ x · π r² dx)
        for i in 0..<slices {
            let xIn = (Double(i) + 0.5) * dxIn
            let rM  = dims.radius(atX: xIn) * Units.inToM
            let dA  = Double.pi * rM * rM           // m²
            let xM  = xIn * Units.inToM
            volume      += dA * dxM
            firstMoment += xM * dA * dxM
        }
        guard volume > 0 else {
            return MechanicsResult(weightLb: dims.weightLb, comFromBottomIn: 0, leverArmIn: 0,
                                   torqueLbFt: 0, torqueLbIn: 0, maxTorqueLbFt: 0,
                                   iTransverseLbIn2: 0, iTransverseSlugFt2: 0, iAxialLbIn2: 0,
                                   angularMomentumSlugFt2PerS: 0,
                                   effectiveDensityKgM3: 0, solidSteelWeightLb: 0)
        }

        let massKg = dims.weightLb * Units.lbToKg
        let rho    = massKg / volume                 // effective uniform density, kg/m³
        let comM   = firstMoment / volume            // m
        let comIn  = comM * Units.mToIn

        // Pass 2: moments of inertia about the grip pivot (mass-weighted).
        var iTrans = 0.0   // kg·m²  ∫ [(x-pivot)² + ¼ r²] dm
        var iAx    = 0.0   // kg·m²  ∫ ½ r² dm
        for i in 0..<slices {
            let xIn = (Double(i) + 0.5) * dxIn
            let rM  = dims.radius(atX: xIn) * Units.inToM
            let xM  = xIn * Units.inToM
            let dm  = rho * Double.pi * rM * rM * dxM    // kg
            let d   = xM - pivotM
            iTrans += (d * d + 0.25 * rM * rM) * dm
            iAx    += 0.5 * rM * rM * dm
        }

        // Gravitational torque about the grip: τ = m g (lever) sin θ
        let leverInSigned = comIn - gripCenterIn
        let leverM = leverInSigned * Units.inToM
        let theta  = angleFromVerticalDeg * .pi / 180
        let tauNm    = massKg * Units.g * leverM * sin(theta)
        let tauMaxNm = massKg * Units.g * abs(leverM)        // at horizontal

        // Angular momentum about the wrist:  L = I_transverse · ω
        let omega = rpm * 2 * .pi / 60                       // rad/s
        let Lsi   = iTrans * omega                           // kg·m²/s

        return MechanicsResult(
            weightLb: dims.weightLb,
            comFromBottomIn: comIn,
            leverArmIn: leverInSigned,
            torqueLbFt: tauNm * Units.nmToLbFt,
            torqueLbIn: tauNm * Units.nmToLbIn,
            maxTorqueLbFt: tauMaxNm * Units.nmToLbFt,
            iTransverseLbIn2: iTrans * Units.kgm2ToLbIn2,
            iTransverseSlugFt2: iTrans * Units.kgm2ToSlugFt2,
            iAxialLbIn2: iAx * Units.kgm2ToLbIn2,
            angularMomentumSlugFt2PerS: Lsi * Units.kgm2ToSlugFt2,
            effectiveDensityKgM3: rho,
            solidSteelWeightLb: Units.steelDensity * volume * Units.kgToLb
        )
    }
}
