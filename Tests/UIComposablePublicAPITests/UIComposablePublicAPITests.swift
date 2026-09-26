import Testing
import SwiftUI
import UIComposable

@Test("UIComposable을_채택한_외부_UIView가_composable을_제공한다")
@MainActor
func UIComposable을_채택한_외부_UIView가_composable을_제공한다() {
    _ = UIComposablePublicView.composable()
}

@Test("UIComposable을_채택한_외부_UIView가_sizeThatFits_composable을_제공한다")
@MainActor
func UIComposable을_채택한_외부_UIView가_sizeThatFits_composable을_제공한다() {
    _ = UIComposablePublicView.composable(sizeThatFits: { _, _ in nil })
}

@Test("UIComposable을_채택한_외부_UIViewController가_composable을_제공한다")
@MainActor
func UIComposable을_채택한_외부_UIViewController가_composable을_제공한다() {
    _ = UIComposablePublicViewController.composable()
}

@Test("UIComposable을_채택한_외부_UIViewController가_sizeThatFits_composable을_제공한다")
@MainActor
func UIComposable을_채택한_외부_UIViewController가_sizeThatFits_composable을_제공한다() {
    _ = UIComposablePublicViewController.composable(sizeThatFits: { _, _ in nil })
}

@Test("UICoordinatedComposable을_채택한_외부_UIView가_composable을_제공한다")
@MainActor
func UICoordinatedComposable을_채택한_외부_UIView가_composable을_제공한다() {
    _ = UICoordinatedPublicView.composable()
}

@Test("UICoordinatedComposable을_채택한_외부_UIView가_sizeThatFits_composable을_제공한다")
@MainActor
func UICoordinatedComposable을_채택한_외부_UIView가_sizeThatFits_composable을_제공한다() {
    _ = UICoordinatedPublicView.composable(sizeThatFits: { _, _ in nil })
}

@Test("UICoordinatedComposable을_채택한_외부_UIViewController가_composable을_제공한다")
@MainActor
func UICoordinatedComposable을_채택한_외부_UIViewController가_composable을_제공한다() {
    _ = UICoordinatedPublicViewController.composable()
}

@Test("UICoordinatedComposable을_채택한_외부_UIViewController가_sizeThatFits_composable을_제공한다")
@MainActor
func UICoordinatedComposable을_채택한_외부_UIViewController가_sizeThatFits_composable을_제공한다() {
    _ = UICoordinatedPublicViewController.composable(sizeThatFits: { _, _ in nil })
}

@MainActor
private final class UIComposablePublicView: UIView, UIComposable {}

@MainActor
private final class UIComposablePublicViewController: UIViewController, UIComposable {}

@MainActor
private final class UICoordinatedPublicView: UIView, UICoordinatedComposable {
    final class Coordinator {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func connect(coordinator: Coordinator) {}

    func update(coordinator: Coordinator) {}

    func disconnect(coordinator: Coordinator) {}
}

@MainActor
private final class UICoordinatedPublicViewController: UIViewController, UICoordinatedComposable {
    final class Coordinator {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func connect(coordinator: Coordinator) {}

    func update(coordinator: Coordinator) {}

    func disconnect(coordinator: Coordinator) {}
}
