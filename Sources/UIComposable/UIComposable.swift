import SwiftUI

/// UIKit 객체를 SwiftUI에서 표시할 수 있도록 하는 프로토콜입니다.
///
/// `UIView` 또는 `UIViewController` 하위 타입에서 채택하고 타입의 정적
/// `composable(update:)`를 호출합니다. SwiftUI가 처음 표시할 때 Bridge가
/// ``init()``으로 객체를 생성하고 이후 갱신에는 실제 표시 중인 객체를 사용합니다.
/// UIKit 객체 생성과 갱신은 모두 메인 액터에서 실행됩니다.
///
/// Delegate 연결이나 외부 자원 정리가 필요하면 ``UICoordinatedComposable``을
/// 채택합니다. 호출 지점의 제네릭 제약이 `UIComposable`이어도 실제 객체가
/// `UICoordinatedComposable`을 채택했다면 Coordinator 생명주기를 실행합니다.
///
/// 사용 방법과 정리 책임은 각각 <doc:UIComposable>과 <doc:CoordinatorLifecycle>을 참고하세요.
@MainActor
public protocol UIComposable: AnyObject {
    /// Bridge가 처음 표시할 UIKit 객체를 생성합니다.
    ///
    /// 연결할 Delegate나 외부 자원의 등록은
    /// ``UICoordinatedComposable/connect(coordinator:)``에서 수행할 수 있습니다.
    init()
}

/// Coordinator를 사용해 UIKit 객체의 연결, 갱신, 정리를 수행하는 프로토콜입니다.
///
/// 최초 표시에서 ``UIComposable/init()``으로 UIKit 객체를 생성한 뒤
/// ``makeCoordinator()``, ``connect(coordinator:)``, 외부 `update` 클로저,
/// ``update(coordinator:)`` 순서로 실행합니다. 이후 갱신에는 같은 표시 객체와
/// Coordinator를 사용하며 외부 `update`를 적용한 뒤 `update(coordinator:)`를 호출합니다.
///
/// SwiftUI가 UIKit 객체를 제거할 때 ``disconnect(coordinator:)``를 호출합니다.
/// UIComposable은 호출 순서를 관리하고 사용처는 자신이 만든 연결과 외부 자원을
/// 정리합니다. 이 계약은 `UIView`와 `UIViewController`에 동일하게 적용됩니다.
///
/// - Important: `disconnect` 호출은 객체 해제를 보장하지 않습니다. Delegate,
///   Observer, Timer, Task, 콜백이나 상호 강한 참조는 사용처에서 직접 정리해야 합니다.
///
/// <doc:CoordinatorLifecycle>과 <doc:ResourceCleanup>에서 구현 예제를 확인할 수 있습니다.
@MainActor
public protocol UICoordinatedComposable: UIComposable {
    /// 연결 상태와 외부 자원을 보관하는 참조 타입입니다.
    ///
    /// UIComposable은 연결된 동안 이 객체를 보관합니다. Coordinator가 UIKit 객체를
    /// 강하게 참조하고 UIKit 객체도 Coordinator를 강하게 참조하면 순환이 생길 수 있습니다.
    associatedtype Coordinator: AnyObject

    /// 처음 표시할 UIKit 객체에 연결할 Coordinator를 생성합니다.
    ///
    /// 같은 표시 객체의 갱신에는 이 메서드가 반환한 Coordinator를 계속 사용합니다.
    /// SwiftUI가 새 표시 객체를 생성하면 새 Coordinator도 생성합니다.
    ///
    /// - Returns: 이 UIKit 객체의 연결과 정리를 담당할 Coordinator입니다.
    func makeCoordinator() -> Coordinator

    /// 표시할 UIKit 객체에 Coordinator를 연결합니다.
    ///
    /// Delegate 연결과 Observer, Timer, Task 등록처럼 갱신마다 반복할 필요가 없는
    /// 작업을 수행합니다. 외부 `update` 클로저보다 먼저 호출되므로 그 클로저에서
    /// 전달하는 값은 ``update(coordinator:)``에서 반영합니다.
    ///
    /// - Parameter coordinator: ``makeCoordinator()``가 생성한 Coordinator입니다.
    func connect(coordinator: Coordinator)

    /// 외부 `update` 클로저가 반영한 값을 Coordinator에 전달합니다.
    ///
    /// 최초 표시와 이후 갱신에서 모두 호출됩니다. 여러 번 호출해도 Delegate나
    /// Observer를 중복 등록하지 않도록 연결 작업은 ``connect(coordinator:)``에 둡니다.
    ///
    /// - Parameter coordinator: 표시 객체에 연결된 기존 Coordinator입니다.
    func update(coordinator: Coordinator)

    /// SwiftUI가 UIKit 객체를 제거할 때 사용처의 연결과 외부 자원을 정리합니다.
    ///
    /// 실제 표시 객체와 그 객체에 연결했던 Coordinator로 호출됩니다.
    /// 자신이 연결한 Delegate와 Observer를 제거하고 Timer를 무효화하며 Task에 취소를
    /// 요청합니다. 보관한 콜백과 상호 강한 참조도 이 메서드에서 끊어야 합니다.
    /// 호출이 끝나면 UIComposable은 내부에서 Coordinator를 보관하던 클로저를 비웁니다.
    ///
    /// - Important: UIComposable은 사용처의 자원이나 참조를 자동으로 정리하지 않습니다.
    ///   다른 강한 참조나 순환이 남아 있으면 이 메서드가 호출된 뒤에도 객체가 살아 있습니다.
    ///   `Task.cancel()`도 취소 요청이며 작업의 즉시 종료나 객체 해제를 보장하지 않습니다.
    ///
    /// - Parameter coordinator: 이 객체를 연결하고 갱신할 때 사용한 Coordinator입니다.
    ///
    /// <doc:CoordinatorLifecycle>과 <doc:ResourceCleanup>을 참고하세요.
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
    /// 이 `UIView` 타입을 SwiftUI에서 표시합니다.
    ///
    /// UIKit 객체는 SwiftUI가 처음 표시할 때 생성합니다. Coordinator가 필요한
    /// 타입이면 ``UICoordinatedComposable``의 연결, 갱신, 정리 메서드도 호출합니다.
    ///
    /// - Parameter update: 최초 표시와 이후 갱신에서 실제 표시 객체에 값을 반영하는
    ///   클로저입니다. Coordinator 갱신보다 먼저 실행되며 반복 호출될 수 있습니다.
    /// - Returns: 이 UIKit 객체를 표시하는 SwiftUI 뷰입니다.
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewBridge<Self>(update: update)
    }

    /// 이 `UIView` 타입을 SwiftUI에서 표시하고 제안된 크기로 필요한 크기를 계산합니다.
    ///
    /// `sizeThatFits`는 배치 과정에서 반복 호출될 수 있으며 Coordinator를 갱신하지
    /// 않습니다. 상태를 바꾸지 않고 크기만 계산해야 합니다.
    ///
    /// - Parameters:
    ///   - update: 최초 표시와 이후 갱신에서 실제 표시 객체에 값을 반영하는 클로저입니다.
    ///   - sizeThatFits: SwiftUI가 제안한 크기와 실제 표시 객체를 받아 필요한 크기를
    ///     반환하는 클로저입니다. `nil`을 반환하면 SwiftUI의 기본 크기 계산을 사용합니다.
    /// - Returns: 이 UIKit 객체를 표시하는 SwiftUI 뷰입니다.
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        UIViewBridge<Self>(update: update, sizing: sizeThatFits)
    }
}

public extension UIComposable where Self: UIViewController {
    /// 이 `UIViewController` 타입을 SwiftUI에서 표시합니다.
    ///
    /// UIKit 객체는 SwiftUI가 처음 표시할 때 생성합니다. Coordinator가 필요한
    /// 타입이면 ``UICoordinatedComposable``의 연결, 갱신, 정리 메서드도 호출합니다.
    ///
    /// - Parameter update: 최초 표시와 이후 갱신에서 실제 표시 객체에 값을 반영하는
    ///   클로저입니다. Coordinator 갱신보다 먼저 실행되며 반복 호출될 수 있습니다.
    /// - Returns: 이 UIKit 객체를 표시하는 SwiftUI 뷰입니다.
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in }
    ) -> some View {
        UIViewControllerBridge<Self>(update: update)
    }

    /// 이 `UIViewController` 타입을 SwiftUI에서 표시하고 필요한 크기를 계산합니다.
    ///
    /// `sizeThatFits`는 배치 과정에서 반복 호출될 수 있으며 Coordinator를 갱신하지
    /// 않습니다. 상태를 바꾸지 않고 크기만 계산해야 합니다.
    ///
    /// - Parameters:
    ///   - update: 최초 표시와 이후 갱신에서 실제 표시 객체에 값을 반영하는 클로저입니다.
    ///   - sizeThatFits: SwiftUI가 제안한 크기와 실제 표시 객체를 받아 필요한 크기를
    ///     반환하는 클로저입니다. `nil`을 반환하면 SwiftUI의 기본 크기 계산을 사용합니다.
    /// - Returns: 이 UIKit 객체를 표시하는 SwiftUI 뷰입니다.
    static func composable(
        update: @escaping @MainActor (Self) -> Void = { _ in },
        sizeThatFits: @escaping @MainActor (ProposedViewSize, Self) -> CGSize?
    ) -> some View {
        UIViewControllerBridge<Self>(update: update, sizing: sizeThatFits)
    }
}
