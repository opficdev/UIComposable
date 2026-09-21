import SwiftUI

@MainActor
public protocol UIComposable: AnyObject {}

@MainActor
public protocol UICoordinatedComposable: UIComposable {
    associatedtype Coordinator: AnyObject

    func makeCoordinator() -> Coordinator
    func connect(coordinator: Coordinator)
    func update(coordinator: Coordinator)
    func disconnect(coordinator: Coordinator)
}

@MainActor
internal struct UIViewBridge<Content>: UIViewRepresentable where Content: UIView & UIComposable {
    let content: Content
    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(content: Content, update: @escaping @MainActor (Content) -> Void) {
        self.content = content
        self.update = update
        sizing = nil
    }

    init(
        content: Content,
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.content = content
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
    typealias Coordinator = Content.Coordinator

    let content: Content
    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(content: Content, update: @escaping @MainActor (Content) -> Void) {
        self.content = content
        self.update = update
        sizing = nil
    }

    init(
        content: Content,
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.content = content
        self.update = update
        self.sizing = sizing
    }

    func makeCoordinator() -> Coordinator {
        content.makeCoordinator()
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
        uiView.disconnect(coordinator: coordinator)
    }

    func makeContent(coordinator: Coordinator) -> Content {
        content.connect(coordinator: coordinator)
        update(content)
        content.update(coordinator: coordinator)
        return content
    }

    func updateContent(_ content: Content, coordinator: Coordinator) {
        update(content)
        content.update(coordinator: coordinator)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

@MainActor
internal struct UIViewControllerBridge<Content>: UIViewControllerRepresentable where Content: UIViewController & UIComposable {
    let content: Content
    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(content: Content, update: @escaping @MainActor (Content) -> Void) {
        self.content = content
        self.update = update
        sizing = nil
    }

    init(
        content: Content,
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.content = content
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
    typealias Coordinator = Content.Coordinator

    let content: Content
    let update: @MainActor (Content) -> Void
    let sizing: (@MainActor (ProposedViewSize, Content) -> CGSize?)?

    init(content: Content, update: @escaping @MainActor (Content) -> Void) {
        self.content = content
        self.update = update
        sizing = nil
    }

    init(
        content: Content,
        update: @escaping @MainActor (Content) -> Void,
        sizing: @escaping @MainActor (ProposedViewSize, Content) -> CGSize?
    ) {
        self.content = content
        self.update = update
        self.sizing = sizing
    }

    func makeCoordinator() -> Coordinator {
        content.makeCoordinator()
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
        uiViewController.disconnect(coordinator: coordinator)
    }

    func makeContent(coordinator: Coordinator) -> Content {
        content.connect(coordinator: coordinator)
        update(content)
        content.update(coordinator: coordinator)
        return content
    }

    func updateContent(_ content: Content, coordinator: Coordinator) {
        update(content)
        content.update(coordinator: coordinator)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

public extension UIComposable where Self: UIView {
    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewBridge(content: self, update: update)
    }

    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        UIViewBridge(content: self, update: update, sizing: sizeThatFits)
    }
}

public extension UICoordinatedComposable where Self: UIView {
    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        CoordinatedUIViewBridge(content: self, update: update)
    }

    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        CoordinatedUIViewBridge(content: self, update: update, sizing: sizeThatFits)
    }
}

public extension UIComposable where Self: UIViewController {
    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewControllerBridge(content: self, update: update)
    }

    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        UIViewControllerBridge(content: self, update: update, sizing: sizeThatFits)
    }
}

public extension UICoordinatedComposable where Self: UIViewController {
    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        CoordinatedUIViewControllerBridge(content: self, update: update)
    }

    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        CoordinatedUIViewControllerBridge(content: self, update: update, sizing: sizeThatFits)
    }
}
