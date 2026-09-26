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
final class ComposableLifecycleStorage<Content> where Content: AnyObject {
    private var updateLifecycle: (@MainActor (Content) -> Void)?
    private var disconnectLifecycle: (@MainActor (Content) -> Void)?

    func connect(_ content: Content) {
        guard let coordinatedContent = content as? any UICoordinatedComposable else {
            return
        }

        configure(coordinatedContent)
    }

    func update(_ content: Content) {
        updateLifecycle?(content)
    }

    func disconnect(_ content: Content) {
        disconnectLifecycle?(content)
        updateLifecycle = nil
        disconnectLifecycle = nil
    }

    private func configure<CoordinatedContent>(_ content: CoordinatedContent)
    where CoordinatedContent: UICoordinatedComposable {
        let coordinator = content.makeCoordinator()
        content.connect(coordinator: coordinator)

        updateLifecycle = { content in
            guard let coordinatedContent = content as? CoordinatedContent else {
                preconditionFailure("연결된 UIComposable 타입이 변경되었습니다.")
            }

            coordinatedContent.update(coordinator: coordinator)
        }
        disconnectLifecycle = { content in
            guard let coordinatedContent = content as? CoordinatedContent else {
                preconditionFailure("연결된 UIComposable 타입이 변경되었습니다.")
            }

            coordinatedContent.disconnect(coordinator: coordinator)
        }
    }
}

@MainActor
internal struct UIViewBridge<Content>: UIViewRepresentable where Content: UIView & UIComposable {
    typealias Coordinator = ComposableLifecycleStorage<Content>

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
        coordinator.disconnect(uiView)
    }

    func makeContent(coordinator: Coordinator) -> Content {
        let content = Content()
        coordinator.connect(content)
        update(content)
        coordinator.update(content)
        return content
    }

    func updateContent(_ content: Content, coordinator: Coordinator) {
        update(content)
        coordinator.update(content)
    }

    func sizeContent(_ proposal: ProposedViewSize, content: Content) -> CGSize? {
        sizing?(proposal, content)
    }
}

@MainActor
internal struct UIViewControllerBridge<Content>: UIViewControllerRepresentable where Content: UIViewController & UIComposable {
    typealias Coordinator = ComposableLifecycleStorage<Content>

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
        coordinator.disconnect(uiViewController)
    }

    func makeContent(coordinator: Coordinator) -> Content {
        let content = Content()
        coordinator.connect(content)
        update(content)
        coordinator.update(content)
        return content
    }

    func updateContent(_ content: Content, coordinator: Coordinator) {
        update(content)
        coordinator.update(content)
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
