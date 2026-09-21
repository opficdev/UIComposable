import Testing
import SwiftUI
import UIComposable

@Test("UIComposable을_채택한_외부_UIView가_composable을_제공한다")
@MainActor
func UIComposable을_채택한_외부_UIView가_composable을_제공한다() {
    _ = UIComposablePublicView().composable()
}

@Test("UIComposable을_채택한_외부_UIViewController가_composable을_제공한다")
@MainActor
func UIComposable을_채택한_외부_UIViewController가_composable을_제공한다() {
    _ = UIComposablePublicViewController().composable()
}

@MainActor
private final class UIComposablePublicView: UIView, UIComposable {}

@MainActor
private final class UIComposablePublicViewController: UIViewController, UIComposable {}
