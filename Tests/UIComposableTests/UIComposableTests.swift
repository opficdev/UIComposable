import Testing
import Observation
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

@Test("UIViewBridge가_실제_UIView에_update를_적용한다", .timeLimit(.minutes(1)))
@MainActor
func UIViewBridge가_실제_UIView에_update를_적용한다() async {
    let displayed = UIComposableView()
    let candidate = UIComposableView()
    let state = UIComposableUpdateState()
    let recorder = UIComposableUpdateRecorder()
    let host = UIHostingController(
        rootView: UIViewUpdateHost(
            state: state,
            displayed: displayed,
            candidate: candidate,
            recorder: recorder
        )
    )
    _ = host.view

    await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
            recorder.begin(continuation)
            state.usesCandidate = true
        }
    } onCancel: {
        Task { @MainActor in
            recorder.cancel()
        }
    }

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

@Test("UIViewControllerBridge가_실제_UIViewController에_update를_적용한다", .timeLimit(.minutes(1)))
@MainActor
func UIViewControllerBridge가_실제_UIViewController에_update를_적용한다() async {
    let displayed = UIComposableViewController()
    let candidate = UIComposableViewController()
    let state = UIComposableUpdateState()
    let recorder = UIComposableUpdateRecorder()
    let host = UIHostingController(
        rootView: UIViewControllerUpdateHost(
            state: state,
            displayed: displayed,
            candidate: candidate,
            recorder: recorder
        )
    )
    _ = host.view

    await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
            recorder.begin(continuation)
            state.usesCandidate = true
        }
    } onCancel: {
        Task { @MainActor in
            recorder.cancel()
        }
    }

    #expect(displayed.title == "updated")
    #expect(candidate.title == nil)
}

@MainActor
private final class UIComposableView: UIView, UIComposable {}

@MainActor
private final class UIComposableViewController: UIViewController, UIComposable {}

@Observable
@MainActor
private final class UIComposableUpdateState {
    var usesCandidate = false
}

@MainActor
private final class UIComposableUpdateRecorder {
    var continuation: CheckedContinuation<Void, Never>?
    var isCancelled = false

    func begin(_ continuation: CheckedContinuation<Void, Never>) {
        self.continuation = continuation

        if isCancelled {
            resume()
        }
    }

    func confirm() {
        resume()
    }

    func cancel() {
        isCancelled = true
        resume()
    }

    private func resume() {
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
private struct UIViewUpdateHost: View {
    let state: UIComposableUpdateState
    let displayed: UIComposableView
    let candidate: UIComposableView
    let recorder: UIComposableUpdateRecorder

    var body: some View {
        let content = state.usesCandidate ? candidate : displayed

        content.composable { target in
            target.tag = state.usesCandidate ? 2 : 1

            if state.usesCandidate && target === displayed {
                recorder.confirm()
            }
        }
    }
}

@MainActor
private struct UIViewControllerUpdateHost: View {
    let state: UIComposableUpdateState
    let displayed: UIComposableViewController
    let candidate: UIComposableViewController
    let recorder: UIComposableUpdateRecorder

    var body: some View {
        let content = state.usesCandidate ? candidate : displayed

        content.composable { target in
            target.title = state.usesCandidate ? "updated" : "initial"

            if state.usesCandidate && target === displayed {
                recorder.confirm()
            }
        }
    }
}
