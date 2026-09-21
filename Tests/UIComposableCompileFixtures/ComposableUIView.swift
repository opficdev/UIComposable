import SwiftUI
import UIComposable

@MainActor
private final class UIComposableFixtureView: UIView, UIComposable {}

@MainActor
func UIComposable을_채택한_UIView는_composable을_사용할_수_있다() {
    _ = UIComposableFixtureView().composable()
    _ = UIComposableFixtureView().composable(sizeThatFits: { proposal, view in
        guard let width = proposal.width else {
            return nil
        }

        return view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    })
}
