#if DEBUG
import SwiftUI

/// Shared sample data for `#Preview` blocks and the README screenshot
/// generator (`ScreenshotGenTests`). DEBUG-only: never in release builds.
enum ClubbellKitSamples {
    static var selection: ClubSelection { ClubSelection() }

    /// A `ClubProfileView` wired to the default selection's derived mechanics.
    static var profileView: ClubProfileView {
        let s = selection
        return ClubProfileView(
            dims: s.dimensions,
            gripCenterIn: .constant(s.gripCenterIn),
            handWidthIn: s.handWidthIn,
            comFromBottomIn: s.mechanics().comFromBottomIn
        )
    }
}
#endif
