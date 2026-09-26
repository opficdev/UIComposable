import SwiftUI

@MainActor
public protocol UIComposable: AnyObject {
    init()
}

@MainActor
public protocol UICoordinatedComposable: UIComposable {
    associatedtype Coordinator: AnyObject

    func makeCoordinator() -> Coordinator
    func connect(coordinator: Coordinator)
    func update(coordinator: Coordinator)
    func disconnect(coordinator: Coordinator)
}

@MainActor
final class ComposableCoordinatorStorage<Coordinator> where Coordinator: AnyObject {
    var value: Coordinator?
}

@MainActor
internal struct UIViewBridge<Content>: UIViewRepresentable where Content: UIView & UIComposable {
    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(update: @escaping @MainActor (Content) -> Void) {
        self.update = update
        sizing = nil
    }

    init(
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.update = update
        self.sizing = sizing
    }

    func makeUIView(context: Context) -> Content {
        makeContent()
    }

    func updateUIView(_ uiView: Content, context: Context) {
        updateContent(uiView)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: Content, context: Context) -> CGSize? {
        sizeContent(proposal, content: uiView)
    }

    func makeContent() -> Content {
        let content = Content()
        update(content)
        return content
    }

    func updateContent(_ content: Content) {
        update(content)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

@MainActor
struct CoordinatedUIViewBridge<Content>: UIViewRepresentable where Content: UIView & UICoordinatedComposable {
    typealias Coordinator = ComposableCoordinatorStorage<Content.Coordinator>

    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(update: @escaping @MainActor (Content) -> Void) {
        self.update = update
        sizing = nil
    }

    init(
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.update = update
        self.sizing = sizing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> Content {
        makeContent(coordinator: context.coordinator)
    }

    func updateUIView(_ uiView: Content, context: Context) {
        updateContent(uiView, coordinator: context.coordinator)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: Content, context: Context) -> CGSize? {
        sizeContent(proposal, content: uiView)
    }

    static func dismantleUIView(_ uiView: Content, coordinator: Coordinator) {
        guard let contentCoordinator = coordinator.value else {
            return
        }

        uiView.disconnect(coordinator: contentCoordinator)
        coordinator.value = nil
    }

    func makeContent(coordinator: Coordinator) -> Content {
        let content = Content()
        let contentCoordinator = content.makeCoordinator()
        coordinator.value = contentCoordinator
        content.connect(coordinator: contentCoordinator)
        update(content)
        content.update(coordinator: contentCoordinator)
        return content
    }

    func updateContent(_ content: Content, coordinator: Coordinator) {
        guard let contentCoordinator = coordinator.value else {
            preconditionFailure("Coordinator가 생성되지 않았습니다.")
        }

        update(content)
        content.update(coordinator: contentCoordinator)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

@MainActor
internal struct UIViewControllerBridge<Content>: UIViewControllerRepresentable where Content: UIViewController & UIComposable {
    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(update: @escaping @MainActor (Content) -> Void) {
        self.update = update
        sizing = nil
    }

    init(
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.update = update
        self.sizing = sizing
    }

    func makeUIViewController(context: Context) -> Content {
        makeContent()
    }

    func updateUIViewController(_ uiViewController: Content, context: Context) {
        updateContent(uiViewController)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: Content, context: Context) -> CGSize? {
        sizeContent(proposal, content: uiViewController)
    }

    func makeContent() -> Content {
        let content = Content()
        update(content)
        return content
    }

    func updateContent(_ content: Content) {
        update(content)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

@MainActor
struct CoordinatedUIViewControllerBridge<Content>: UIViewControllerRepresentable
where Content: UIViewController & UICoordinatedComposable {
    typealias Coordinator = ComposableCoordinatorStorage<Content.Coordinator>

    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(update: @escaping @MainActor (Content) -> Void) {
        self.update = update
        sizing = nil
    }

    init(
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.update = update
        self.sizing = sizing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> Content {
        makeContent(coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: Content, context: Context) {
        updateContent(uiViewController, coordinator: context.coordinator)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiViewController: Content, context: Context) -> CGSize? {
        sizeContent(proposal, content: uiViewController)
    }

    static func dismantleUIViewController(_ uiViewController: Content, coordinator: Coordinator) {
        guard let contentCoordinator = coordinator.value else {
            return
        }

        uiViewController.disconnect(coordinator: contentCoordinator)
        coordinator.value = nil
    }

    func makeContent(coordinator: Coordinator) -> Content {
        let content = Content()
        let contentCoordinator = content.makeCoordinator()
        coordinator.value = contentCoordinator
        content.connect(coordinator: contentCoordinator)
        update(content)
        content.update(coordinator: contentCoordinator)
        return content
    }

    func updateContent(_ content: Content, coordinator: Coordinator) {
        guard let contentCoordinator = coordinator.value else {
            preconditionFailure("Coordinator가 생성되지 않았습니다.")
        }

        update(content)
        content.update(coordinator: contentCoordinator)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

public extension UIComposable where Self: UIView {
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewBridge<Self>(update: update)
    }

    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        UIViewBridge<Self>(update: update, sizing: sizeThatFits)
    }
}

public extension UICoordinatedComposable where Self: UIView {
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        CoordinatedUIViewBridge<Self>(update: update)
    }

    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        CoordinatedUIViewBridge<Self>(update: update, sizing: sizeThatFits)
    }
}

public extension UIComposable where Self: UIViewController {
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewControllerBridge<Self>(update: update)
    }

    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        UIViewControllerBridge<Self>(update: update, sizing: sizeThatFits)
    }
}

public extension UICoordinatedComposable where Self: UIViewController {
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        CoordinatedUIViewControllerBridge<Self>(update: update)
    }

    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        CoordinatedUIViewControllerBridge<Self>(update: update, sizing: sizeThatFits)
    }
}
