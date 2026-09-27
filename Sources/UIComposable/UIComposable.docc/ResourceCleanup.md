# Delegate와 외부 자원 정리하기

disconnect에서 사용처가 등록한 연결과 자원을 정리합니다.

## 자원별 정리 방법

``UICoordinatedComposable/disconnect(coordinator:)``에서는 사용처가 만든 연결을 끊습니다. 공유 자원이나 다른 객체가 만든 연결까지 제거하지 않도록 자신이 등록한 대상을 구분하세요.

| 자원 | 정리 방법 |
| --- | --- |
| Delegate와 데이터 소스 | 자신이 연결한 객체인지 확인한 뒤 해당 프로퍼티를 `nil`로 설정 |
| NotificationCenter Observer | 등록할 때 받은 토큰으로 `removeObserver(_:)`를 호출한 뒤 보관한 토큰을 비움 |
| KVO Observer | 보관한 `NSKeyValueObservation`의 `invalidate()`를 호출한 뒤 참조를 비움 |
| Timer | `invalidate()`로 반복 호출을 중단한 뒤 보관한 Timer를 비움 |
| Task | `cancel()`로 취소를 요청한 뒤 보관한 Task를 비움. 작업 내부에서도 취소를 확인 |
| 콜백 | UIKit 객체와 Coordinator에 보관한 클로저를 비워 캡처한 참조를 해제 |
| UIKit 객체와 Coordinator의 상호 참조 | 연결할 때 보관한 강한 참조를 끊거나 소유가 필요 없는 방향에 `weak` 참조를 사용 |

## 연결, 갱신, 정리 구현하기

아래 `UITextView` 예제는 Delegate와 NotificationCenter Observer, Timer, Task, 콜백을 한 곳에서 정리하는 방법을 보여 줍니다. 실제 컴포넌트에서는 필요한 자원만 등록하면 됩니다.

```swift
import UIKit
import UIComposable

@MainActor
final class ResourceTextView: UITextView, UICoordinatedComposable {
	@MainActor
	final class ResourceTextViewCoordinator: NSObject, UITextViewDelegate {
		weak var textView: ResourceTextView?
		var observer: NSObjectProtocol?
		var timer: Timer?
		var task: Task<Void, Never>?
		var onTextChange: ((String) -> Void)?

		func textViewDidChange(_ textView: UITextView) {
			onTextChange?(textView.text)
		}

		@objc func didFireTimer(_ timer: Timer) {
			refresh()
		}

		func refresh() {
			guard let textView else {
				return
			}

			onTextChange?(textView.text)
		}
	}

	var onTextChange: ((String) -> Void)?

	func makeCoordinator() -> ResourceTextViewCoordinator {
		ResourceTextViewCoordinator()
	}

	func connect(coordinator: ResourceTextViewCoordinator) {
		coordinator.textView = self
		delegate = coordinator
		coordinator.observer = NotificationCenter.default.addObserver(
			forName: UITextView.textDidChangeNotification,
			object: self,
			queue: .main
		) { [weak coordinator] _ in
			// .main 큐에서 전달하므로 메인 액터의 상태에 접근할 수 있습니다.
			MainActor.assumeIsolated {
				coordinator?.refresh()
			}
		}
		coordinator.timer = Timer.scheduledTimer(
			timeInterval: 1,
			target: coordinator,
			selector: #selector(ResourceTextViewCoordinator.didFireTimer(_:)),
			userInfo: nil,
			repeats: true
		)
	}

	func update(coordinator: ResourceTextViewCoordinator) {
		coordinator.onTextChange = onTextChange
		guard coordinator.task == nil else {
			return
		}

		coordinator.task = Task { @MainActor [weak coordinator] in
			guard !Task.isCancelled else {
				return
			}
			coordinator?.refresh()
			do {
				try await Task.sleep(for: .seconds(1))
			} catch {
				return
			}
			guard !Task.isCancelled else {
				return
			}

			coordinator?.refresh()
		}
	}

	func disconnect(coordinator: ResourceTextViewCoordinator) {
		if delegate === coordinator {
			delegate = nil
		}
		if let observer = coordinator.observer {
			NotificationCenter.default.removeObserver(observer)
			coordinator.observer = nil
		}
		coordinator.timer?.invalidate()
		coordinator.timer = nil
		coordinator.task?.cancel()
		coordinator.task = nil
		coordinator.onTextChange = nil
		onTextChange = nil
		coordinator.textView = nil
	}
}
```

`connect`는 외부 `update`보다 먼저 실행되므로 콜백은 `update(coordinator:)`에서 전달합니다. Task도 콜백을 받은 뒤 한 번만 시작하도록 구성했습니다. `disconnect`에서는 Delegate의 대상을 확인하고 Observer를 제거한 뒤 Timer와 Task를 정리합니다. 마지막으로 콜백과 표시 객체의 참조를 비웁니다.

NotificationCenter의 콜백은 `.main` 큐에서 전달하도록 지정했습니다. Timer도 메인 액터에서 등록하므로 메인 실행 루프에서 호출됩니다. 이 조건을 바꾼다면 콜백에서 UIKit 상태에 접근하는 방법도 함께 바꿔야 합니다.

## Task 취소와 참조 해제

`Task.cancel()`은 취소 요청입니다. `task = nil`로 보관한 참조를 비워도 실행 중인 Task가 즉시 끝나는 것은 아닙니다. 작업은 `Task.isCancelled`나 `Task.checkCancellation()`으로 취소를 확인하거나 취소 시 오류를 던지는 작업의 종료를 처리해야 합니다.

예제는 `Task.sleep`이 취소로 종료되면 반환하고 대기가 끝난 뒤에도 취소 여부를 확인합니다. Coordinator를 `weak`으로 캡처해 Task가 Coordinator를 계속 보관하지 않도록 했습니다. 콜백과 `textView` 참조도 정리하므로 제거 뒤에 남은 콜백이 표시 객체에 값을 전달하지 않습니다.

## UIViewController에 적용하기

`UIViewController`도 같은 정리 책임을 가집니다. 컨트롤러 자신이 보관한 자원뿐 아니라 내부 `view`에 연결한 Delegate와 Observer도 정리해야 합니다.

[CoordinatedDemoCollectionViewController.swift](https://github.com/opficdev/UIComposable/blob/develop/Examples/ExampleApp/UIKit/CoordinatedDemoCollectionViewController.swift)는 내부 `collectionView`의 Delegate와 데이터 소스를 연결한 뒤 `disconnect`에서 자신이 연결한 대상인지 확인하고 해제합니다. 상호 강한 참조를 끊는 방법은 <doc:CoordinatorLifecycle>을 참고하세요.
