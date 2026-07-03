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
