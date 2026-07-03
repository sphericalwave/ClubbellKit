import Foundation

/// All physics is computed internally in SI (metres, kilograms, seconds) for
/// dimensional consistency, then converted to imperial for display.
enum Units {
    // Length / mass / gravity
    static let inToM       = 0.0254
    static let mToIn       = 1.0 / 0.0254
    static let lbToKg      = 0.45359237
    static let kgToLb      = 1.0 / 0.45359237
    static let g           = 9.80665                 // m/s^2
    static let gFtPerS2    = 32.17405                 // ft/s^2 (imperial slugs)

    // Torque:  N·m -> imperial
    static let nmToLbFt    = 0.737562149
    static let nmToLbIn    = 8.85074579

    // Mass moment of inertia:  kg·m^2 -> imperial
    static let kgm2ToLbIn2 = 3417.171                // lb·in² (mass moment)
    static let kgm2ToSlugFt2 = 0.737562149           // slug·ft² (dynamical)

    // Reference: a "solid steel" club, for the uniform-density note in the UI
    static let steelDensity = 7850.0                 // kg/m^3
}
