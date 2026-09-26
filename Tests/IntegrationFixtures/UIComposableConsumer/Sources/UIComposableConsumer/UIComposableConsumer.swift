import SwiftUI
import UIComposable

@MainActor
enum UIComposableConsumerFixture {
	static func basicView() -> some View {
		ConsumerView.composable { view in
			view.backgroundColor = .systemBackground
		}
	}

	static func sizedBasicView() -> some View {
		ConsumerView.composable(
			update: { view in
				view.backgroundColor = .systemBackground
			},
			sizeThatFits: { proposal, view in
				guard let width = proposal.width else {
					return nil
				}

				return view.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
			}
		)
	}

	static func basicViewController() -> some View {
		ConsumerViewController.composable { viewController in
			viewController.title = "UIComposable"
		}
	}

	static func sizedBasicViewController() -> some View {
		ConsumerViewController.composable(
			update: { viewController in
				viewController.title = "UIComposable"
			},
			sizeThatFits: { _, viewController in
				viewController.view.bounds.size
			}
		)
	}

	static func coordinatedView() -> some View {
		ConsumerTextField.composable { textField in
			textField.placeholder = "검색어"
		}
	}

	static func sizedCoordinatedView() -> some View {
		ConsumerTextField.composable(
			update: { textField in
				textField.placeholder = "검색어"
			},
			sizeThatFits: { proposal, textField in
				guard let width = proposal.width else {
					return nil
				}

				return textField.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
			}
		)
	}

	static func coordinatedViewController() -> some View {
		ConsumerViewControllerWithCoordinator.composable()
	}

	static func sizedCoordinatedViewController() -> some View {
		ConsumerViewControllerWithCoordinator.composable(sizeThatFits: { _, viewController in
			viewController.view.bounds.size
		})
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
