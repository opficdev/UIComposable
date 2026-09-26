import SwiftUI
import UIComposable

@MainActor
private final class UIComposableFixtureView: UIView, UIComposable {}

private func mainActor_격리_밖에서는_composable을_사용할_수_없다() {
    _ = UIComposableFixtureView.composable()
}
