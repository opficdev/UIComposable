# Coordinator 생명주기와 정리 책임

UIComposable의 생명주기 호출 순서를 확인하고 UIKit 객체와 Coordinator의 강한 참조를 정리합니다.

## 호출 순서

``UICoordinatedComposable``을 채택한 UIKit 객체는 다음 순서로 연결하고 갱신합니다. `UIView`와 `UIViewController` 모두 같은 순서를 따릅니다.

| 시점 | 순서 |
| --- | --- |
| 최초 표시 | UIKit 객체의 `init()` → ``UICoordinatedComposable/makeCoordinator()`` → ``UICoordinatedComposable/connect(coordinator:)`` → 외부 `update` 클로저 → ``UICoordinatedComposable/update(coordinator:)`` |
| 이후 갱신 | 외부 `update` 클로저 → ``UICoordinatedComposable/update(coordinator:)`` |
| SwiftUI가 UIKit 객체를 제거할 때 | ``UICoordinatedComposable/disconnect(coordinator:)`` → UIComposable이 내부에서 Coordinator를 보관하던 클로저를 비움 |

이후 갱신과 제거 시에는 처음 연결한 표시 객체와 같은 Coordinator를 사용합니다. SwiftUI가 새 표시 객체를 생성하면 새 Coordinator도 생성합니다. 호출 지점의 제네릭 제약이 ``UIComposable/UIComposable``이어도 실제 객체가 `UICoordinatedComposable`을 채택했다면 이 생명주기를 실행합니다.

`connect(coordinator:)`는 외부 `update`보다 먼저 호출됩니다. Delegate와 Observer는 `connect`에서 연결하고 외부 `update`가 전달한 값과 콜백은 `update(coordinator:)`에서 Coordinator에 반영합니다. 외부 `update`와 `update(coordinator:)`는 반복 호출될 수 있으므로 갱신할 때마다 연결을 중복 등록하지 않아야 합니다.

`disconnect`는 SwiftUI가 Bridge의 UIKit 객체를 제거할 때 호출됩니다. 화면이 가려지거나 SwiftUI의 `onDisappear`가 호출되는 것만으로 이 정리가 실행된다고 가정하지 마세요.

## disconnect 호출과 객체 해제

UIComposable은 `disconnect(coordinator:)`를 실제 표시 객체와 연결된 Coordinator에 호출합니다. 사용처는 이 메서드에서 자신이 만든 연결과 외부 자원을 정리해야 합니다.

Delegate와 Observer, Timer, Task, 콜백은 자동으로 정리되지 않습니다. UIKit 객체와 Coordinator 사이의 강한 참조도 UIComposable이 대신 끊지 않습니다. 정리할 자원별 구현은 <doc:ResourceCleanup>을 참고하세요.

`disconnect`가 끝나면 UIComposable은 내부에서 Coordinator를 보관하던 클로저를 비웁니다. 그러나 사용처의 강한 참조 순환이나 다른 소유자의 강한 참조가 남아 있으면 객체는 계속 살아 있습니다. 객체가 해제되려면 그 객체를 보관하는 모든 강한 참조가 사라져야 합니다.

## 상호 강한 참조가 남는 구현

다음 예제는 `UILabel`이 Coordinator를 보관하고 Coordinator도 `UILabel`을 강하게 참조합니다. `disconnect`가 호출되어도 아무 참조를 끊지 않으므로 순환이 남습니다.

```swift
import UIKit
import UIComposable

@MainActor
final class StrongReferenceCycleLabel: UILabel, UICoordinatedComposable {
	@MainActor
	final class StrongReferenceCycleCoordinator {
		var content: StrongReferenceCycleLabel?
	}

	private var retainedCoordinator: StrongReferenceCycleCoordinator?

	func makeCoordinator() -> StrongReferenceCycleCoordinator {
		StrongReferenceCycleCoordinator()
	}

	func connect(coordinator: StrongReferenceCycleCoordinator) {
		retainedCoordinator = coordinator
		coordinator.content = self
	}

	func update(coordinator: StrongReferenceCycleCoordinator) {}

	func disconnect(coordinator: StrongReferenceCycleCoordinator) {}
}
```

이 상태에서는 화면에서 제거한 뒤에도 객체와 Coordinator가 서로를 보관합니다. `deinit`에서만 참조를 끊으려 하면 순환 때문에 `deinit`에 도달하지 못할 수 있습니다.

## disconnect에서 참조 끊기

위 예제의 `disconnect(coordinator:)`를 다음 구현으로 바꾸면 연결할 때 보관한 두 참조를 비울 수 있습니다.

```swift
func disconnect(coordinator: StrongReferenceCycleCoordinator) {
	coordinator.content = nil
	retainedCoordinator = nil
}
```

한쪽의 강한 참조만 끊어도 순환은 사라집니다. 이 구현은 UIKit 객체와 Coordinator가 연결할 때 보관한 참조를 모두 정리합니다. 다른 소유자가 객체를 강하게 참조하고 있다면 그 참조가 사라질 때까지 객체는 유지됩니다.

Coordinator가 UIKit 객체를 소유할 필요가 없다면 `content`를 `weak` 참조로 선언해 순환을 예방할 수도 있습니다. `weak` 참조를 사용하더라도 Observer 제거와 Timer 무효화, Task 취소 등 필요한 정리는 수행해야 합니다.

## ExampleApp과 대조하기

[LifecycleRiskDemo.swift](https://github.com/opficdev/UIComposable/blob/develop/Examples/ExampleApp/Demos/LifecycleRiskDemo.swift)의 세 번째 영역은 `StrongReferenceCycleLabel`의 `disconnect`에서 참조를 끊지 않는 구현입니다. 화면에서 제거하면 정리 호출 횟수를 기록하고 별도의 `breakCycle()` 호출이 상호 강한 참조를 끊습니다.

객체를 한 번 표시한 뒤 제거 처리가 끝났을 때 확인할 항목은 다음과 같습니다.

| 동작 | disconnect 호출 수 | 살아 있는 객체 수 |
| --- | --- | --- |
| 화면에서 제거 | 1 | 1 |
| 강한 참조 직접 해제 | 1 | 0 |

이 결과는 사용처가 만든 참조 순환을 보여 줍니다. 정상적인 구현에서는 별도의 해제 버튼 대신 `disconnect`에서 위와 같이 참조를 끊어야 합니다.

Delegate와 데이터 소스, Coordinator의 콜백을 정리하는 실제 구현은 [CoordinatedDemoCollectionView.swift](https://github.com/opficdev/UIComposable/blob/develop/Examples/ExampleApp/UIKit/CoordinatedDemoCollectionView.swift)와 [CoordinatedDemoCollectionViewController.swift](https://github.com/opficdev/UIComposable/blob/develop/Examples/ExampleApp/UIKit/CoordinatedDemoCollectionViewController.swift)에서 확인할 수 있습니다. 두 구현 모두 자신이 연결한 Delegate와 데이터 소스를 확인해 해제하고 Coordinator가 보관한 콜백을 비웁니다.
