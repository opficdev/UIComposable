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

@Test("UIComposable_제약이_UICoordinatedComposable_UIView의_composable을_제공한다")
@MainActor
func UIComposable_제약이_UICoordinatedComposable_UIView의_composable을_제공한다() {
    _ = composableUIView(UICoordinatedPublicView.self)
    _ = fittingComposableUIView(UICoordinatedPublicView.self)
}

@Test("UIComposable_제약이_UICoordinatedComposable_UIViewController의_composable을_제공한다")
@MainActor
func UIComposable_제약이_UICoordinatedComposable_UIViewController의_composable을_제공한다() {
    _ = composableUIViewController(UICoordinatedPublicViewController.self)
    _ = fittingComposableUIViewController(UICoordinatedPublicViewController.self)
}

@MainActor
private func composableUIView<Content>(_ content: Content.Type) -> some View
where Content: UIView & UIComposable {
    content.composable()
}

@MainActor
private func fittingComposableUIView<Content>(_ content: Content.Type) -> some View
where Content: UIView & UIComposable {
    content.composable(sizeThatFits: { _, _ in nil })
}

@MainActor
private func composableUIViewController<Content>(_ content: Content.Type) -> some View
where Content: UIViewController & UIComposable {
    content.composable()
}

@MainActor
private func fittingComposableUIViewController<Content>(_ content: Content.Type) -> some View
where Content: UIViewController & UIComposable {
    content.composable(sizeThatFits: { _, _ in nil })
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
