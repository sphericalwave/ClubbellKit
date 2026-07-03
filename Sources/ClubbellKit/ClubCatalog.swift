import Foundation

/// Reference clubbells from club_geometry.csv (weight lb, geometry in inches).
public enum ClubCatalog {
    public static let all: [ClubDimensions] = [
        ClubDimensions(ballDiameter: 1.796875, gripDiameter: 0.96875,  gripLength: 8,     taperLength: 9,   barrelDiameter: 2.125,   barrelLength: 1.75, weightLb: 5),
        ClubDimensions(ballDiameter: 1.875,    gripDiameter: 1,        gripLength: 9,     taperLength: 9,   barrelDiameter: 2.875,   barrelLength: 4.75, weightLb: 10),
        ClubDimensions(ballDiameter: 1.84375,  gripDiameter: 1.28125,  gripLength: 8.5,   taperLength: 8.5, barrelDiameter: 3.34375, barrelLength: 6,    weightLb: 15),
        ClubDimensions(ballDiameter: 1.921875, gripDiameter: 1.34375,  gripLength: 9.25,  taperLength: 7.5, barrelDiameter: 3.5625,  barrelLength: 6,    weightLb: 20),
        ClubDimensions(ballDiameter: 1.9375,   gripDiameter: 1.671875, gripLength: 10,    taperLength: 6,   barrelDiameter: 3.71875, barrelLength: 8.5,  weightLb: 25),
        ClubDimensions(ballDiameter: 1.9375,   gripDiameter: 1.5,      gripLength: 9.375, taperLength: 7,   barrelDiameter: 4.25,    barrelLength: 10,   weightLb: 35),
        ClubDimensions(ballDiameter: 1.9375,   gripDiameter: 1.59375,  gripLength: 9,     taperLength: 7.5, barrelDiameter: 4.5625,  barrelLength: 11,   weightLb: 45),
    ]

    /// Display name for a catalog entry, e.g. "15 lb".
    public static func name(_ dims: ClubDimensions) -> String {
        String(format: "%.0f lb", dims.weightLb)
    }
}
