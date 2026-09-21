import SwiftUI
import UIKit
import UIComposable

@MainActor
enum UIComposableConsumerFixture {
	static func basicView() -> some View {
		ConsumerView().composable { view in
			view.backgroundColor = .systemBackground
		}
	}

	static func basicViewController() -> some View {
		ConsumerViewController().composable { viewController in
			viewController.title = "UIComposable"
		}
	}

	static func coordinatedView() -> some View {
		ConsumerTextField().composable { textField in
			textField.placeholder = "검색어"
		}
	}

	static func coordinatedViewController() -> some View {
		ConsumerViewControllerWithCoordinator().composable()
	}
}

@MainActor
private final class ConsumerView: UIView, UIComposable {}

@MainActor
private final class ConsumerViewController: UIViewController, UIComposable {}

@MainActor
private final class ConsumerTextField: UITextField, UICoordinatedComposable {
	final class Coordinator: NSObject, UITextFieldDelegate {
		weak var textField: ConsumerTextField?
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	func connect(coordinator: Coordinator) {
		coordinator.textField = self
		delegate = coordinator
	}

	func update(coordinator: Coordinator) {}

	func disconnect(coordinator: Coordinator) {
		if delegate === coordinator {
			delegate = nil
		}
		coordinator.textField = nil
	}
}

@MainActor
private final class ConsumerViewControllerWithCoordinator: UIViewController, UICoordinatedComposable {
	final class Coordinator {}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	func connect(coordinator: Coordinator) {}

	func update(coordinator: Coordinator) {}

	func disconnect(coordinator: Coordinator) {}
}
