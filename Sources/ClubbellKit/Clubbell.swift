//
//  Clubbell.swift
//  ClubbellKit
//
//  EquipmentKit conformance — makes clubbells pluggable into any
//  set-logging UI that speaks `EquipmentModel`.
//

import SwiftUI
import EquipmentKit

public enum Clubbell: EquipmentModel {
    public typealias Payload = ClubSelection

    public static let equipmentID = "clubbell"
    public static let displayName = "Clubbell"
    public static let inputTitle = "Clubbell & grip"

    public static func summary(_ payload: ClubSelection) -> String {
        let club = ClubCatalog.name(payload.dimensions)
        return payload.isTwoHanded ? "\(club), two-handed" : club
    }

    @MainActor
    public static func inputView(payload: Binding<ClubSelection?>,
                                 suggested: ClubSelection?) -> ClubbellInputView {
        ClubbellInputView(payload: payload, suggested: suggested)
    }
}

/// Bridges the optional `EquipmentModel` payload onto `ClubGripSelector`'s
/// non-optional binding. First render materializes the suggestion (or a
/// default selection) so the selector always has a value to edit.
public struct ClubbellInputView: View {
    @Binding var payload: ClubSelection?
    let suggested: ClubSelection?

    public var body: some View {
        ClubGripSelector(selection: Binding(
            get: { payload ?? suggested ?? ClubSelection() },
            set: { payload = $0 }
        ))
        .onAppear {
            if payload == nil { payload = suggested ?? ClubSelection() }
        }
    }
}

#if DEBUG
#Preview("ClubbellInputView") {
    Form {
        ClubbellInputView(payload: .constant(ClubSelection()), suggested: nil)
            .frame(height: 320)
    }
}
#endif
