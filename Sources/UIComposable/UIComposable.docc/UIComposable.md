# ``UIComposable``

UIKit 객체를 SwiftUI에서 표시하고 Coordinator의 연결과 정리 시점을 관리합니다.

## UIKit 컴포넌트 표시하기

iOS 17 이상에서 사용할 수 있습니다. `UIView` 또는 `UIViewController` 하위 타입에 ``UIComposable/UIComposable``을 채택하고 타입의 정적 `composable(update:)`를 호출합니다.

```swift
import SwiftUI
import UIComposable

@MainActor
final class MessageLabel: UILabel, UIComposable {}

struct MessageView: View {
	var body: some View {
		MessageLabel.composable { label in
			label.text = "안녕하세요"
			label.textAlignment = .center
		}
	}
}
```

Bridge는 SwiftUI가 처음 표시할 때 무매개변수 `init()`으로 UIKit 객체를 생성합니다. 이후 갱신에서는 실제 표시 중인 객체에 `update` 클로저를 적용합니다. 객체 생성과 갱신은 모두 메인 액터에서 실행됩니다.

## Coordinator 사용하기

Delegate 연결이나 외부 자원 정리가 필요하면 ``UICoordinatedComposable``을 채택합니다. 사용처가 Coordinator의 생성과 UIKit별 연결 방법을 구현하고 UIComposable이 호출 순서를 관리합니다.

<doc:CoordinatorLifecycle>에서는 생성, 연결, 갱신, 정리 순서와 상호 강한 참조를 끊는 방법을 설명합니다. <doc:ResourceCleanup>에서는 Delegate와 Observer, Timer, Task, 콜백의 정리 예제를 제공합니다.

`disconnect(coordinator:)`가 호출되었다고 객체가 반드시 해제되는 것은 아닙니다. 사용처에서 만든 연결과 강한 참조를 직접 정리해야 합니다.

## 크기 계산하기

`composable(update:sizeThatFits:)`의 `sizeThatFits` 클로저는 SwiftUI가 제안한 크기와 실제 표시 객체를 받습니다. 필요한 크기를 반환하거나 `nil`을 반환해 SwiftUI의 기본 크기 계산을 사용할 수 있습니다.

크기 계산은 Coordinator 갱신과 별도로 호출되며 배치 과정에서 반복될 수 있습니다. 이 클로저에서는 상태를 바꾸지 않고 크기만 계산합니다.

## Topics

### 컴포넌트 정의

- ``UIComposable/UIComposable``
- ``UICoordinatedComposable``

### 생명주기와 정리

- <doc:CoordinatorLifecycle>
- <doc:ResourceCleanup>
