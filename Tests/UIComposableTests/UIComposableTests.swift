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

@MainActor
private final class UIComposableView: UIView, UIComposable {}

@MainActor
private final class UIComposableViewController: UIViewController, UIComposable {}
