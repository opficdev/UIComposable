import SwiftUI
import UIComposable

@MainActor
private final class UIComposableFixtureView: UIView, UIComposable {}

@MainActor
private func 인스턴스에서는_composable을_사용할_수_없다() {
    _ = UIComposableFixtureView().composable()
}
