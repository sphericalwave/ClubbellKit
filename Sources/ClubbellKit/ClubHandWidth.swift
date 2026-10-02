import SwiftUI

/// The user's hand width — a body measurement, set once in the host app's
/// settings rather than per set. Stored in `UserDefaults.standard` under
/// `storageKey`; `ClubGripSelector` reads it and applies it to every selection.
public enum ClubHandWidth {
    public static let storageKey = "clubbellHandWidthIn"
    public static let defaultIn = 4.0
    public static let range: ClosedRange<Double> = 2...8
    public static let step = 0.25
}

/// Stepper bound to the stored hand width, for a host app's settings or
/// onboarding.
public struct ClubHandWidthStepper: View {
    @AppStorage(ClubHandWidth.storageKey) private var handWidthIn = ClubHandWidth.defaultIn

    public init() {}

    public var body: some View {
        Stepper(value: $handWidthIn, in: ClubHandWidth.range, step: ClubHandWidth.step) {
            HStack {
                Text("Hand width")
                Spacer()
                Text(String(format: "%.2f in", handWidthIn))
                    .monospacedDigit().foregroundStyle(.secondary)
            }
        }
    }
}
