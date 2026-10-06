import XCTest
@testable import ClubbellKit

final class ClubbellKitTests: XCTestCase {

    /// Density is back-solved, so the modelled weight is always the target weight.
    func testWeightMatchesTargetForWholeCatalog() {
        for dims in ClubCatalog.all {
            let r = ClubMechanics.compute(dims: dims, gripCenterIn: 6,
                                          angleFromVerticalDeg: 90, rpm: 0)
            XCTAssertEqual(r.weightLb, dims.weightLb, accuracy: 1e-9)
            XCTAssertGreaterThan(r.effectiveDensityKgM3, 0)
        }
    }

    /// No rod pokes out past the knob: the body radius is zero left of the knob centre.
    func testKnobCapsTheShaft() {
        let d = ClubDimensions.sample
        let rk = d.ballDiameter / 2
        XCTAssertEqual(d.radius(atX: rk * 0.25, includeKnob: false), 0, accuracy: 1e-9)
        XCTAssertGreaterThan(d.radius(atX: rk * 0.25, includeKnob: true), 0)  // sphere still there
    }

    /// `gripLength` is the bare handle measured on a real club: from where it
    /// leaves the knob to the taper (15 lb club measured at 8.5 in).
    func testGripLengthIsTheBareHandleAfterTheKnob() {
        let d = ClubCatalog.all.first { $0.weightLb == 15 }!
        let rg = d.gripDiameter / 2
        XCTAssertEqual(d.gripEnd - d.knobLength, 8.5, accuracy: 1e-9)
        // Straight handle radius right after the knob face and right before the taper.
        XCTAssertEqual(d.radius(atX: d.knobLength + 0.05), rg, accuracy: 1e-9)
        XCTAssertEqual(d.radius(atX: d.gripEnd - 0.05), rg, accuracy: 1e-9)
        XCTAssertGreaterThan(d.radius(atX: d.gripEnd + 0.5), rg)   // taper has begun
        XCTAssertEqual(d.totalLength, d.knobLength + 8.5 + d.taperLength + d.barrelLength, accuracy: 1e-9)
    }

    /// clampGrip keeps the whole hand on the shaft, off the knob.
    func testGripClampStaysOffKnob() {
        var sel = ClubSelection(dimensions: .sample, gripCenterIn: 0, handWidthIn: 4)
        sel.clampGrip()
        XCTAssertGreaterThanOrEqual(sel.gripCenterIn, sel.gripLowerBound - 1e-9)
        XCTAssertLessThanOrEqual(sel.gripCenterIn, sel.gripUpperBound + 1e-9)
    }

    func testSelectionRoundTripsThroughCodable() throws {
        let sel = ClubSelection(dimensions: ClubCatalog.all[2], gripCenterIn: 7, handWidthIn: 4)
        let data = try JSONEncoder().encode(sel)
        let back = try JSONDecoder().decode(ClubSelection.self, from: data)
        XCTAssertEqual(sel, back)
    }
}

// MARK: - EquipmentModel conformance

import EquipmentKit

extension ClubbellKitTests {
    func testClubbellPayloadRoundTrip() {
        var sel = ClubSelection()
        sel.enableSecondGrip()
        let data = EquipmentPayloadCodec.encode(Clubbell.self, sel)
        XCTAssertEqual(EquipmentPayloadCodec.decode(Clubbell.self, from: data), sel)
        XCTAssertEqual(EquipmentPayloadCodec.equipmentID(of: data), "clubbell")
    }

    func testClubbellSummaryNamesClubAndGrip() {
        var sel = ClubSelection()
        XCTAssertFalse(Clubbell.summary(sel).isEmpty)
        sel.enableSecondGrip()
        XCTAssertTrue(Clubbell.summary(sel).hasSuffix("two-handed"))
    }
}

// MARK: - Normalization (catalog snap + stored hand width)

extension ClubbellKitTests {
    func testNormalizedSnapsOffCatalogClubToNearestWeight() {
        // `.sample` is a 15 lb club that isn't in the catalog.
        let sel = ClubSelection().normalized(to: ClubCatalog.all, handWidthIn: 4)
        XCTAssertEqual(sel.dimensions, ClubCatalog.all.first { $0.weightLb == 15 })
    }

    func testNormalizedKeepsCatalogClubAndAppliesHandWidth() {
        let five = ClubCatalog.all[0]
        let sel = ClubSelection(dimensions: five, gripCenterIn: 3)
            .normalized(to: ClubCatalog.all, handWidthIn: 3.25)
        XCTAssertEqual(sel.dimensions, five)
        XCTAssertEqual(sel.handWidthIn, 3.25)
        XCTAssertGreaterThanOrEqual(sel.gripCenterIn, sel.gripLowerBound)
    }
}
