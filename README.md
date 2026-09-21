# UIComposable

UIKit 인스턴스를 SwiftUI의 `.composable(update:)`로 표시하는 Swift Package입니다.

## UICoordinatedComposable

Delegate처럼 별도 객체가 필요한 UIKit 컴포넌트는 `UICoordinatedComposable`을 채택합니다. `Coordinator` 생성과 UIKit별 연결 방법은 컴포넌트가 소유하고, Bridge는 lifecycle 호출 순서만 관리합니다.

```swift
import SwiftUI
import UIComposable

@MainActor
final class SearchField: UITextField, UICoordinatedComposable {
    final class SearchFieldCoordinator: NSObject, UITextFieldDelegate {
        weak var searchField: SearchField?

        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Delegate callback 처리
        }
    }

    func makeCoordinator() -> SearchFieldCoordinator {
        SearchFieldCoordinator()
    }

    func connect(coordinator: SearchFieldCoordinator) {
        coordinator.searchField = self
        delegate = coordinator
    }

    func update(coordinator: SearchFieldCoordinator) {
        // 외부 update 이후 Coordinator 상태 동기화
    }

    func disconnect(coordinator: SearchFieldCoordinator) {
        if delegate === coordinator {
            delegate = nil
        }
        coordinator.searchField = nil
    }
}

struct SearchView: View {
    var body: some View {
        SearchField().composable { searchField in
            searchField.placeholder = "검색어"
        }
    }
}
```

## lifecycle

SwiftUI identity마다 `makeCoordinator()`가 한 번 호출됩니다.

1. 최초 표시에서 `connect(coordinator:)`, 외부 `update`, `update(coordinator:)` 순으로 호출됩니다.
2. 이후 갱신에서 실제 표시 UIKit 인스턴스에 외부 `update`를 적용한 뒤, 같은 Coordinator로 `update(coordinator:)`를 호출합니다.
3. identity가 사라질 때 실제 표시 UIKit 인스턴스와 같은 Coordinator로 `disconnect(coordinator:)`를 호출합니다.

identity가 바뀌면 새 Coordinator가 생성될 수 있습니다. 외부 `update`와 `update(coordinator:)`는 반복 호출에도 같은 결과를 내도록 구현해야 합니다.

## 제네릭 제약

`composable(update:)`의 선택은 호출 지점의 정적 타입을 따릅니다. Coordinator lifecycle이 필요한 제네릭 함수는 `UICoordinatedComposable` 제약을 명시해야 합니다.

```swift
@MainActor
func coordinatedView<T>(_ content: T) -> some View
where T: UIView & UICoordinatedComposable {
    content.composable()
}
```

`T: UIComposable`만 선언한 제네릭 함수는 기본 Bridge를 선택하므로 Coordinator lifecycle을 호출하지 않습니다.
