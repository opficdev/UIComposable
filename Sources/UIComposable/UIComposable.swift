import SwiftUI

@MainActor
public protocol UIComposable: AnyObject {}

@MainActor
internal struct UIViewBridge<Content>: UIViewRepresentable where Content: UIView & UIComposable {
    let content: Content
    let update: @MainActor (Content) -> Void

    func makeUIView(context: Context) -> Content {
        makeContent()
    }

    func updateUIView(_ uiView: Content, context: Context) {
        updateContent(uiView)
    }

    func makeContent() -> Content {
        update(content)
        return content
    }

    func updateContent(_ content: Content) {
        update(content)
    }
}

@MainActor
internal struct UIViewControllerBridge<Content>: UIViewControllerRepresentable where Content: UIViewController & UIComposable {
    let content: Content
    let update: @MainActor (Content) -> Void

    func makeUIViewController(context: Context) -> Content {
        makeContent()
    }

    func updateUIViewController(_ uiViewController: Content, context: Context) {
        updateContent(uiViewController)
    }

    func makeContent() -> Content {
        update(content)
        return content
    }

    func updateContent(_ content: Content) {
        update(content)
    }
}

public extension UIComposable where Self: UIView {
    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewBridge(content: self, update: update)
    }
}

public extension UIComposable where Self: UIViewController {
    func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewControllerBridge(content: self, update: update)
    }
}
