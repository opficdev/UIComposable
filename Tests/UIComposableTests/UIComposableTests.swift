import Testing
import SwiftUI
@testable import UIComposable

@Test("UIViewBridge가_최초_UIView에_update를_적용한다")
@MainActor
func UIViewBridge가_최초_UIView에_update를_적용한다() {
    let view = UIComposableView()
    let bridge = UIViewBridge(content: view) { target in
        target.tag = 1
    }

    let displayed = bridge.makeContent()

    #expect(displayed === view)
    #expect(displayed.tag == 1)
}

@Test("UIViewBridge가_실제_UIView에_update를_적용한다")
@MainActor
func UIViewBridge가_실제_UIView에_update를_적용한다() {
    let displayed = UIComposableView()
    let initialBridge = UIViewBridge(content: displayed) { target in
        target.tag = 1
    }
    _ = initialBridge.makeContent()

    let candidate = UIComposableView()
    let updatedBridge = UIViewBridge(content: candidate) { target in
        target.tag = 2
    }
    updatedBridge.updateContent(displayed)

    #expect(displayed.tag == 2)
    #expect(candidate.tag == 0)
}

@Test("CoordinatedUIViewBridge가_Coordinator_lifecycle을_실제_UIView에_적용한다")
@MainActor
func coordinatedUIViewBridge가_Coordinator_lifecycle을_실제_UIView에_적용한다() {
    let events = CoordinatorLifecycleEvents()
    let displayed = UICoordinatedView(events: events)
    let bridge = CoordinatedUIViewBridge(content: displayed) { target in
        events.values.append("initial update")
        target.tag = 1
    }
    let coordinator = bridge.makeCoordinator()
    let made = bridge.makeContent(coordinator: coordinator)
    let candidate = UICoordinatedView(events: events)
    let updatedBridge = CoordinatedUIViewBridge(content: candidate) { target in
        events.values.append("updated update")
        target.tag = 2
    }

    updatedBridge.updateContent(displayed, coordinator: coordinator)
    CoordinatedUIViewBridge<UICoordinatedView>.dismantleUIView(displayed, coordinator: coordinator)

    #expect(displayed === made)
    #expect(displayed.tag == 2)
    #expect(candidate.tag == 0)
    #expect(displayed.makeCoordinatorCallCount == 1)
    #expect(coordinator.connectedContent === displayed)
    #expect(coordinator.updatedContent === displayed)
    #expect(coordinator.disconnectedContent === displayed)
    #expect(events.values == ["connect", "initial update", "coordinator update", "updated update", "coordinator update", "disconnect"])
}

@Test("UICoordinatedComposable_UIView가_Coordinator_Bridge를_선택한다")
@MainActor
func UICoordinatedComposable_UIView가_Coordinator_Bridge를_선택한다() {
    let composable = UICoordinatedView(events: CoordinatorLifecycleEvents()).composable()

    #expect(composable is CoordinatedUIViewBridge<UICoordinatedView>)
}

@Test("UIView_제네릭_제약이_composable_Bridge를_선택한다")
@MainActor
func UIView_제네릭_제약이_composable_Bridge를_선택한다() {
    let content = UICoordinatedView(events: CoordinatorLifecycleEvents())
    let basicComposable = basicUIViewComposable(content)
    let coordinatedComposable = coordinatedUIViewComposable(content)

    #expect(basicComposable is UIViewBridge<UICoordinatedView>)
    #expect(coordinatedComposable is CoordinatedUIViewBridge<UICoordinatedView>)
}

@Test("UIViewControllerBridge가_최초_UIViewController에_update를_적용한다")
@MainActor
func UIViewControllerBridge가_최초_UIViewController에_update를_적용한다() {
    let viewController = UIComposableViewController()
    let bridge = UIViewControllerBridge(content: viewController) { target in
        target.title = "created"
    }

    let displayed = bridge.makeContent()

    #expect(displayed === viewController)
    #expect(displayed.title == "created")
}

@Test("UIViewControllerBridge가_실제_UIViewController에_update를_적용한다")
@MainActor
func UIViewControllerBridge가_실제_UIViewController에_update를_적용한다() {
    let displayed = UIComposableViewController()
    let initialBridge = UIViewControllerBridge(content: displayed) { target in
        target.title = "initial"
    }
    _ = initialBridge.makeContent()

    let candidate = UIComposableViewController()
    let updatedBridge = UIViewControllerBridge(content: candidate) { target in
        target.title = "updated"
    }
    updatedBridge.updateContent(displayed)

    #expect(displayed.title == "updated")
    #expect(candidate.title == nil)
}

@Test("CoordinatedUIViewControllerBridge가_Coordinator_lifecycle을_실제_UIViewController에_적용한다")
@MainActor
func coordinatedUIViewControllerBridge가_Coordinator_lifecycle을_실제_UIViewController에_적용한다() {
    let events = CoordinatorLifecycleEvents()
    let displayed = UICoordinatedViewController(events: events)
    let bridge = CoordinatedUIViewControllerBridge(content: displayed) { target in
        events.values.append("initial update")
        target.title = "initial"
    }
    let coordinator = bridge.makeCoordinator()
    let made = bridge.makeContent(coordinator: coordinator)
    let candidate = UICoordinatedViewController(events: events)
    let updatedBridge = CoordinatedUIViewControllerBridge(content: candidate) { target in
        events.values.append("updated update")
        target.title = "updated"
    }

    updatedBridge.updateContent(displayed, coordinator: coordinator)
    CoordinatedUIViewControllerBridge<UICoordinatedViewController>.dismantleUIViewController(displayed, coordinator: coordinator)

    #expect(displayed === made)
    #expect(displayed.title == "updated")
    #expect(candidate.title == nil)
    #expect(displayed.makeCoordinatorCallCount == 1)
    #expect(coordinator.connectedContent === displayed)
    #expect(coordinator.updatedContent === displayed)
    #expect(coordinator.disconnectedContent === displayed)
    #expect(events.values == ["connect", "initial update", "coordinator update", "updated update", "coordinator update", "disconnect"])
}

@Test("UICoordinatedComposable_UIViewController가_Coordinator_Bridge를_선택한다")
@MainActor
func UICoordinatedComposable_UIViewController가_Coordinator_Bridge를_선택한다() {
    let composable = UICoordinatedViewController(events: CoordinatorLifecycleEvents()).composable()

    #expect(composable is CoordinatedUIViewControllerBridge<UICoordinatedViewController>)
}

@Test("UIViewController_제네릭_제약이_composable_Bridge를_선택한다")
@MainActor
func UIViewController_제네릭_제약이_composable_Bridge를_선택한다() {
    let content = UICoordinatedViewController(events: CoordinatorLifecycleEvents())
    let basicComposable = basicUIViewControllerComposable(content)
    let coordinatedComposable = coordinatedUIViewControllerComposable(content)

    #expect(basicComposable is UIViewControllerBridge<UICoordinatedViewController>)
    #expect(coordinatedComposable is CoordinatedUIViewControllerBridge<UICoordinatedViewController>)
}

@MainActor
private func basicUIViewComposable<Content>(_ content: Content) -> some View where Content: UIView & UIComposable {
    content.composable()
}

@MainActor
private func coordinatedUIViewComposable<Content>(_ content: Content) -> some View where Content: UIView & UICoordinatedComposable {
    content.composable()
}

@MainActor
private func basicUIViewControllerComposable<Content>(_ content: Content) -> some View where Content: UIViewController & UIComposable {
    content.composable()
}

@MainActor
private func coordinatedUIViewControllerComposable<Content>(_ content: Content) -> some View
where Content: UIViewController & UICoordinatedComposable {
    content.composable()
}

@MainActor
private final class UIComposableView: UIView, UIComposable {}

@MainActor
private final class UIComposableViewController: UIViewController, UIComposable {}

@MainActor
private final class UICoordinatedView: UIView, UICoordinatedComposable {
    final class Coordinator {
        weak var connectedContent: UICoordinatedView?
        weak var updatedContent: UICoordinatedView?
        weak var disconnectedContent: UICoordinatedView?
    }

    let events: CoordinatorLifecycleEvents
    private(set) var makeCoordinatorCallCount = 0

    init(events: CoordinatorLifecycleEvents) {
        self.events = events
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

    let events: CoordinatorLifecycleEvents
    private(set) var makeCoordinatorCallCount = 0

    init(events: CoordinatorLifecycleEvents) {
        self.events = events
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
