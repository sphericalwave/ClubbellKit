import SwiftUI

/// Minimal drop-in UI: pick a catalog clubbell and place the grip. Writes through
/// to a `ClubSelection` the host app owns and persists — e.g. on a progYog skill
/// to scale its challenge.
///
/// ```swift
/// @State private var selection = ClubSelection()
/// ClubGripSelector(selection: $selection)
/// ```
public struct ClubGripSelector: View {
    @Binding var selection: ClubSelection
    let catalog: [ClubDimensions]
    /// Set once in the host app's settings (see `ClubHandWidth`), not per set.
    @AppStorage(ClubHandWidth.storageKey) private var handWidthIn = ClubHandWidth.defaultIn

    public init(selection: Binding<ClubSelection>,
                catalog: [ClubDimensions] = ClubCatalog.all) {
        self._selection = selection
        self.catalog = catalog
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Clubbell", selection: clubBinding) {
                ForEach(catalog.indices, id: \.self) { i in
                    Text(ClubCatalog.name(catalog[i])).tag(i)
                }
            }
            .pickerStyle(.segmented)

            ClubProfileView(dims: selection.dimensions,
                            gripCenterIn: $selection.gripCenterIn,
                            handWidthIn: selection.handWidthIn,
                            comFromBottomIn: selection.mechanics().comFromBottomIn,
                            secondGripCenterIn: secondGripBinding)

            HStack {
                Label(selection.secondGripCenterIn == nil ? "Grip" : "Lower hand",
                      systemImage: "hand.point.up.left")
                Slider(value: $selection.gripCenterIn,
                       in: selection.gripLowerBound...selection.gripUpperBound)
                Text(String(format: "%.1f in", selection.gripCenterIn))
                    .monospacedDigit().frame(width: 58, alignment: .trailing)
            }

            if let upper = secondGripBinding {
                HStack {
                    Label("Upper hand", systemImage: "hand.point.up")
                    Slider(value: upper,
                           in: selection.gripLowerBound...selection.gripUpperBound)
                    Text(String(format: "%.1f in", upper.wrappedValue))
                        .monospacedDigit().frame(width: 58, alignment: .trailing)
                }
            }

            Toggle("Two-handed", isOn: twoHandedBinding)
        }
        .onChange(of: selection.dimensions) { _, _ in selection.clampGrip() }
        .onChange(of: handWidthIn) { _, _ in normalize() }
        .onAppear { normalize() }
    }

    /// Apply the stored hand width and snap an off-catalog club, otherwise the
    /// picker highlights the first club while the profile draws a different one.
    private func normalize() {
        let s = selection.normalized(to: catalog, handWidthIn: handWidthIn)
        if s != selection { selection = s }
    }

    /// Non-optional binding to the second hand, present only when two-handed.
    private var secondGripBinding: Binding<Double>? {
        guard selection.secondGripCenterIn != nil else { return nil }
        return Binding(
            get: { selection.secondGripCenterIn ?? selection.gripCenterIn },
            set: { selection.secondGripCenterIn = $0 }
        )
    }

    /// Toggles the second hand on/off.
    private var twoHandedBinding: Binding<Bool> {
        Binding(
            get: { selection.secondGripCenterIn != nil },
            set: { on in
                if on { selection.enableSecondGrip() } else { selection.disableSecondGrip() }
            }
        )
    }

    /// Picker works on the catalog index, mapped to/from the selected dimensions.
    private var clubBinding: Binding<Int> {
        Binding(
            get: { catalog.firstIndex(of: selection.dimensions) ?? 0 },
            set: { selection.dimensions = catalog[$0]; selection.clampGrip() }
        )
    }
}

#if DEBUG
#Preview("ClubGripSelector") {
    ClubGripSelector(selection: .constant(ClubSelection()))
        .frame(height: 320)
        .padding()
}
#endif
