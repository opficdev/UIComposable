import Testing
import SwiftUI
@testable import UIComposable

@Test("UIViewBridge는_makeContent가_호출될_때_UIView를_생성한다")
@MainActor
func UIViewBridge는_makeContent가_호출될_때_UIView를_생성한다() {
    UIComposableView.creationCount = 0
    let bridge = UIViewBridge<UIComposableView> { target in
        target.tag = 1
    }

    #expect(UIComposableView.creationCount == 0)

    let displayed = bridge.makeContent()

    #expect(UIComposableView.creationCount == 1)
    #expect(displayed.tag == 1)
}

@Test("UIViewBridge는_후속_갱신에서_새_UIView를_생성하지_않는다")
@MainActor
func UIViewBridge는_후속_갱신에서_새_UIView를_생성하지_않는다() {
    UIComposableView.creationCount = 0
    let initialBridge = UIViewBridge<UIComposableView> { target in
        target.tag = 1
    }
    let displayed = initialBridge.makeContent()
    let updatedBridge = UIViewBridge<UIComposableView> { target in
        target.tag = 2
    }

    updatedBridge.updateContent(displayed)

    #expect(UIComposableView.creationCount == 1)
    #expect(displayed.tag == 2)
}

@Test("UIViewBridge가_실제_UIView에_sizeThatFits를_적용한다")
@MainActor
func UIViewBridge가_실제_UIView에_sizeThatFits를_적용한다() {
    let displayed = UIComposableView()
    var received: UIComposableView?
    var receivedWidth: CGFloat?
    let bridge = UIViewBridge<UIComposableView>(update: { _ in }, sizing: { proposal, view in
        received = view
        receivedWidth = proposal.width
        return CGSize(width: 120, height: 80)
    })

    let size = bridge.sizeContent(ProposedViewSize(width: nil, height: 80), content: displayed)

    #expect(size == CGSize(width: 120, height: 80))
    #expect(received === displayed)
    #expect(receivedWidth == nil)
}

@Test("UIViewBridge가_sizing_미지정_시_nil을_반환한다")
@MainActor
func UIViewBridge가_sizing_미지정_시_nil을_반환한다() {
    let view = UIComposableView()
    let bridge = UIViewBridge<UIComposableView>(update: { _ in })

    #expect(bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: view) == nil)
}

@Test("SwiftUI가_UIViewBridge의_sizeThatFits_hook을_호출한다")
@MainActor
func SwiftUI가_UIViewBridge의_sizeThatFits_hook을_호출한다() {
    var received: UIComposableView?
    let bridge = UIViewBridge<UIComposableView>(update: { _ in }, sizing: { _, view in
        received = view
        return CGSize(width: 120, height: 80)
    })

    measure(bridge)

    #expect(received != nil)
}

@Test("CoordinatedUIViewBridge가_Coordinator_lifecycle을_실제_UIView에_적용한다")
@MainActor
func coordinatedUIViewBridge가_Coordinator_lifecycle을_실제_UIView에_적용한다() throws {
    UICoordinatedView.creationCount = 0
    let bridge = CoordinatedUIViewBridge<UICoordinatedView> { target in
        target.events.values.append("initial update")
        target.tag = 1
    }
    let storage = bridge.makeCoordinator()

    #expect(UICoordinatedView.creationCount == 0)

    let displayed = bridge.makeContent(coordinator: storage)
    let coordinator = try #require(storage.value)
    let updatedBridge = CoordinatedUIViewBridge<UICoordinatedView> { target in
        target.events.values.append("updated update")
        target.tag = 2
    }

    updatedBridge.updateContent(displayed, coordinator: storage)
    CoordinatedUIViewBridge<UICoordinatedView>.dismantleUIView(displayed, coordinator: storage)

    #expect(UICoordinatedView.creationCount == 1)
    #expect(displayed.tag == 2)
    #expect(displayed.makeCoordinatorCallCount == 1)
    #expect(coordinator.connectedContent === displayed)
    #expect(coordinator.updatedContent === displayed)
    #expect(coordinator.disconnectedContent === displayed)
    #expect(storage.value == nil)
    #expect(displayed.events.values == [
        "connect",
        "initial update",
        "coordinator update",
        "updated update",
        "coordinator update",
        "disconnect"
    ])
}

@Test("CoordinatedUIViewBridge가_실제_UIView에_sizeThatFits를_적용하고_Coordinator를_갱신하지_않는다")
@MainActor
func coordinatedUIViewBridge가_실제_UIView에_sizeThatFits를_적용하고_Coordinator를_갱신하지_않는다() {
    let displayed = UICoordinatedView()
    var received: UICoordinatedView?
    let bridge = CoordinatedUIViewBridge<UICoordinatedView>(update: { _ in }, sizing: { _, view in
        received = view
        return CGSize(width: 120, height: 80)
    })

    let size = bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: displayed)

    #expect(size == CGSize(width: 120, height: 80))
    #expect(received === displayed)
    #expect(displayed.events.values.isEmpty)
}

@Test("CoordinatedUIViewBridge가_sizing_미지정_시_nil을_반환한다")
@MainActor
func coordinatedUIViewBridge가_sizing_미지정_시_nil을_반환한다() {
    let view = UICoordinatedView()
    let bridge = CoordinatedUIViewBridge<UICoordinatedView>(update: { _ in })

    #expect(bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: view) == nil)
    #expect(view.events.values.isEmpty)
}

@Test("SwiftUI가_CoordinatedUIViewBridge의_sizeThatFits_hook을_호출한다")
@MainActor
func SwiftUI가_CoordinatedUIViewBridge의_sizeThatFits_hook을_호출한다() {
    var received: UICoordinatedView?
    let bridge = CoordinatedUIViewBridge<UICoordinatedView>(update: { _ in }, sizing: { _, view in
        received = view
        return CGSize(width: 120, height: 80)
    })

    measure(bridge)

    #expect(received != nil)
}

@Test("UICoordinatedComposable_UIView가_Coordinator_Bridge를_선택한다")
@MainActor
func UICoordinatedComposable_UIView가_Coordinator_Bridge를_선택한다() {
    let composable = UICoordinatedView.composable()

    #expect(composable is CoordinatedUIViewBridge<UICoordinatedView>)
}

@Test("UIView_제네릭_제약이_composable_Bridge를_선택한다")
@MainActor
func UIView_제네릭_제약이_composable_Bridge를_선택한다() {
    let basicComposable = basicUIViewComposable(UICoordinatedView.self)
    let coordinatedComposable = coordinatedUIViewComposable(UICoordinatedView.self)

    #expect(basicComposable is UIViewBridge<UICoordinatedView>)
    #expect(coordinatedComposable is CoordinatedUIViewBridge<UICoordinatedView>)
}

@Test("UIViewControllerBridge는_makeContent가_호출될_때_UIViewController를_생성한다")
@MainActor
func UIViewControllerBridge는_makeContent가_호출될_때_UIViewController를_생성한다() {
    UIComposableViewController.creationCount = 0
    let bridge = UIViewControllerBridge<UIComposableViewController> { target in
        target.title = "created"
    }

    #expect(UIComposableViewController.creationCount == 0)

    let displayed = bridge.makeContent()

    #expect(UIComposableViewController.creationCount == 1)
    #expect(displayed.title == "created")
}

@Test("UIViewControllerBridge는_후속_갱신에서_새_UIViewController를_생성하지_않는다")
@MainActor
func UIViewControllerBridge는_후속_갱신에서_새_UIViewController를_생성하지_않는다() {
    UIComposableViewController.creationCount = 0
    let initialBridge = UIViewControllerBridge<UIComposableViewController> { target in
        target.title = "initial"
    }
    let displayed = initialBridge.makeContent()
    let updatedBridge = UIViewControllerBridge<UIComposableViewController> { target in
        target.title = "updated"
    }

    updatedBridge.updateContent(displayed)

    #expect(UIComposableViewController.creationCount == 1)
    #expect(displayed.title == "updated")
}

@Test("UIViewControllerBridge가_실제_UIViewController에_sizeThatFits를_적용한다")
@MainActor
func UIViewControllerBridge가_실제_UIViewController에_sizeThatFits를_적용한다() {
    let displayed = UIComposableViewController()
    var received: UIComposableViewController?
    var receivedHeight: CGFloat?
    let bridge = UIViewControllerBridge<UIComposableViewController>(update: { _ in }, sizing: { proposal, view in
        received = view
        receivedHeight = proposal.height
        return CGSize(width: 120, height: 80)
    })

    let size = bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: displayed)

    #expect(size == CGSize(width: 120, height: 80))
    #expect(received === displayed)
    #expect(receivedHeight == nil)
}

@Test("UIViewControllerBridge가_sizing_미지정_시_nil을_반환한다")
@MainActor
func UIViewControllerBridge가_sizing_미지정_시_nil을_반환한다() {
    let viewController = UIComposableViewController()
    let bridge = UIViewControllerBridge<UIComposableViewController>(update: { _ in })

    #expect(bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: viewController) == nil)
}

@Test("SwiftUI가_UIViewControllerBridge의_sizeThatFits_hook을_호출한다")
@MainActor
func SwiftUI가_UIViewControllerBridge의_sizeThatFits_hook을_호출한다() {
    var received: UIComposableViewController?
    let bridge = UIViewControllerBridge<UIComposableViewController>(update: { _ in }, sizing: { _, viewController in
        received = viewController
        return CGSize(width: 120, height: 80)
    })

    measure(bridge)

    #expect(received != nil)
}

@Test("CoordinatedUIViewControllerBridge가_Coordinator_lifecycle을_실제_UIViewController에_적용한다")
@MainActor
func coordinatedUIViewControllerBridge가_Coordinator_lifecycle을_실제_UIViewController에_적용한다() throws {
    UICoordinatedViewController.creationCount = 0
    let bridge = CoordinatedUIViewControllerBridge<UICoordinatedViewController> { target in
        target.events.values.append("initial update")
        target.title = "initial"
    }
    let storage = bridge.makeCoordinator()

    #expect(UICoordinatedViewController.creationCount == 0)

    let displayed = bridge.makeContent(coordinator: storage)
    let coordinator = try #require(storage.value)
    let updatedBridge = CoordinatedUIViewControllerBridge<UICoordinatedViewController> { target in
        target.events.values.append("updated update")
        target.title = "updated"
    }

    updatedBridge.updateContent(displayed, coordinator: storage)
    CoordinatedUIViewControllerBridge<UICoordinatedViewController>.dismantleUIViewController(
        displayed,
        coordinator: storage
    )

    #expect(UICoordinatedViewController.creationCount == 1)
    #expect(displayed.title == "updated")
    #expect(displayed.makeCoordinatorCallCount == 1)
    #expect(coordinator.connectedContent === displayed)
    #expect(coordinator.updatedContent === displayed)
    #expect(coordinator.disconnectedContent === displayed)
    #expect(storage.value == nil)
    #expect(displayed.events.values == [
        "connect",
        "initial update",
        "coordinator update",
        "updated update",
        "coordinator update",
        "disconnect"
    ])
}

@Test("CoordinatedUIViewControllerBridge가_실제_UIViewController에_sizeThatFits를_적용하고_Coordinator를_갱신하지_않는다")
@MainActor
func coordinatedUIViewControllerBridge가_실제_UIViewController에_sizeThatFits를_적용하고_Coordinator를_갱신하지_않는다() {
    let displayed = UICoordinatedViewController()
    var received: UICoordinatedViewController?
    let bridge = CoordinatedUIViewControllerBridge<UICoordinatedViewController>(update: { _ in }, sizing: { _, view in
        received = view
        return CGSize(width: 120, height: 80)
    })

    let size = bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: displayed)

    #expect(size == CGSize(width: 120, height: 80))
    #expect(received === displayed)
    #expect(displayed.events.values.isEmpty)
}

@Test("CoordinatedUIViewControllerBridge가_sizing_미지정_시_nil을_반환한다")
@MainActor
func coordinatedUIViewControllerBridge가_sizing_미지정_시_nil을_반환한다() {
    let viewController = UICoordinatedViewController()
    let bridge = CoordinatedUIViewControllerBridge<UICoordinatedViewController>(update: { _ in })

    #expect(bridge.sizeContent(ProposedViewSize(width: 120, height: nil), content: viewController) == nil)
    #expect(viewController.events.values.isEmpty)
}

@Test("SwiftUI가_CoordinatedUIViewControllerBridge의_sizeThatFits_hook을_호출한다")
@MainActor
func SwiftUI가_CoordinatedUIViewControllerBridge의_sizeThatFits_hook을_호출한다() {
    var received: UICoordinatedViewController?
    let bridge = CoordinatedUIViewControllerBridge<UICoordinatedViewController>(update: { _ in }, sizing: { _, viewController in
        received = viewController
        return CGSize(width: 120, height: 80)
    })

    measure(bridge)

    #expect(received != nil)
}

@Test("UICoordinatedComposable이_sizeThatFits_composable에서_Coordinator_Bridge를_선택한다")
@MainActor
func UICoordinatedComposable이_sizeThatFits_composable에서_Coordinator_Bridge를_선택한다() {
    let view = UICoordinatedView.composable(sizeThatFits: { _, _ in nil })
    let viewController = UICoordinatedViewController.composable(sizeThatFits: { _, _ in nil })

    #expect(view is CoordinatedUIViewBridge<UICoordinatedView>)
    #expect(viewController is CoordinatedUIViewControllerBridge<UICoordinatedViewController>)
}

@Test("UICoordinatedComposable_UIViewController가_Coordinator_Bridge를_선택한다")
@MainActor
func UICoordinatedComposable_UIViewController가_Coordinator_Bridge를_선택한다() {
    let composable = UICoordinatedViewController.composable()

    #expect(composable is CoordinatedUIViewControllerBridge<UICoordinatedViewController>)
}

@Test("UIViewController_제네릭_제약이_composable_Bridge를_선택한다")
@MainActor
func UIViewController_제네릭_제약이_composable_Bridge를_선택한다() {
    let basicComposable = basicUIViewControllerComposable(UICoordinatedViewController.self)
    let coordinatedComposable = coordinatedUIViewControllerComposable(UICoordinatedViewController.self)

    #expect(basicComposable is UIViewControllerBridge<UICoordinatedViewController>)
    #expect(coordinatedComposable is CoordinatedUIViewControllerBridge<UICoordinatedViewController>)
}

@MainActor
private func basicUIViewComposable<Content>(_ content: Content.Type) -> some View
where Content: UIView & UIComposable {
    content.composable()
}

@MainActor
private func coordinatedUIViewComposable<Content>(_ content: Content.Type) -> some View
where Content: UIView & UICoordinatedComposable {
    content.composable()
}

@MainActor
private func basicUIViewControllerComposable<Content>(_ content: Content.Type) -> some View
where Content: UIViewController & UIComposable {
    content.composable()
}

@MainActor
private func coordinatedUIViewControllerComposable<Content>(_ content: Content.Type) -> some View
where Content: UIViewController & UICoordinatedComposable {
    content.composable()
}

@MainActor
private func measure<Content>(_ content: Content) where Content: View {
    let host = UIHostingController(rootView: content)
    host.loadViewIfNeeded()
    _ = host.sizeThatFits(in: CGSize(width: 120, height: CGFloat.greatestFiniteMagnitude))
}

@MainActor
private final class UIComposableView: UIView, UIComposable {
    static var creationCount = 0

    init() {
        Self.creationCount += 1
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private final class UIComposableViewController: UIViewController, UIComposable {
    static var creationCount = 0

    init() {
        Self.creationCount += 1
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private final class UICoordinatedView: UIView, UICoordinatedComposable {
    final class Coordinator {
        weak var connectedContent: UICoordinatedView?
        weak var updatedContent: UICoordinatedView?
        weak var disconnectedContent: UICoordinatedView?
    }

    static var creationCount = 0

    let events = CoordinatorLifecycleEvents()
    private(set) var makeCoordinatorCallCount = 0

    init() {
        Self.creationCount += 1
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeCoordinator() -> Coordinator {
        makeCoordinatorCallCount += 1
        return Coordinator()
    }

    func connect(coordinator: Coordinator) {
        events.values.append("connect")
        coordinator.connectedContent = self
    }

    func update(coordinator: Coordinator) {
        events.values.append("coordinator update")
        coordinator.updatedContent = self
    }

    func disconnect(coordinator: Coordinator) {
        events.values.append("disconnect")
        coordinator.disconnectedContent = self
    }
}

@MainActor
private final class UICoordinatedViewController: UIViewController, UICoordinatedComposable {
    final class Coordinator {
        weak var connectedContent: UICoordinatedViewController?
        weak var updatedContent: UICoordinatedViewController?
        weak var disconnectedContent: UICoordinatedViewController?
    }

    static var creationCount = 0

    let events = CoordinatorLifecycleEvents()
    private(set) var makeCoordinatorCallCount = 0

    init() {
        Self.creationCount += 1
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeCoordinator() -> Coordinator {
        makeCoordinatorCallCount += 1
        return Coordinator()
    }

    func connect(coordinator: Coordinator) {
        events.values.append("connect")
        coordinator.connectedContent = self
    }

    func update(coordinator: Coordinator) {
        events.values.append("coordinator update")
        coordinator.updatedContent = self
    }

    func disconnect(coordinator: Coordinator) {
        events.values.append("disconnect")
        coordinator.disconnectedContent = self
    }
}

@MainActor
private final class CoordinatorLifecycleEvents {
    var values: [String] = []
}
