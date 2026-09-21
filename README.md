<h1 align="center">UIComposable</h1>

<p align="center">
  UIKit 인스턴스를 SwiftUI의 `.composable(update:)`로 표시해요.
</p>

<p align="center">
  <a href="#설치">설치</a>
  <a href="#첫-composable">첫 composable</a>
  <a href="#coordinator-연결">Coordinator 연결</a>
  <a href="LICENSE">MIT License</a>
</p>

<br />

UIComposable은 `UIView`와 `UIViewController` 인스턴스를 SwiftUI 화면에 연결해요. 기본 Bridge는 외부 `update`만 적용하고, Delegate처럼 별도 객체가 필요한 경우에는 `UICoordinatedComposable`이 Coordinator lifecycle을 관리해요.

iOS 17 이상과 Swift 6 이상이 필요해요.

## 설치

UIComposable은 Swift Package Manager에서 `0.1.0`부터 설치해요. `0.x.y`에서는 minor version이 호환성을 보장하지 않으므로 새 기능을 자동으로 받으려면 `Up to Next Minor Version`을 선택해요.

Xcode에서는 **File > Add Package Dependencies...**를 선택하고 아래 URL을 입력해요. Dependency Rule은 **Up to Next Minor Version**, 버전은 `0.1.0`으로 설정해요.

```
https://github.com/opficdev/UIComposable.git
```

`Package.swift`에서는 다음 dependency와 product를 target에 추가해요.

```swift
dependencies: [
	.package(
		url: "https://github.com/opficdev/UIComposable.git",
		.upToNextMinor(from: "0.1.0")
	)
]
```

```swift
.target(
	name: "AppFeature",
	dependencies: [
		.product(name: "UIComposable", package: "UIComposable")
	]
)
```

재현 가능한 build가 필요하면 Dependency Rule을 **Exact Version**으로 설정하거나 `Package.swift`의 dependency를 `.exact("0.1.0")`으로 바꿔요.

## 첫 composable

`UIComposable`을 채택한 `UIView` 또는 `UIViewController`에서 `.composable(update:)`를 호출해요. SwiftUI가 다시 그릴 때마다 실제로 표시 중인 UIKit 인스턴스에 `update`가 적용돼요.

```swift
import SwiftUI
import UIKit
import UIComposable

@MainActor
final class AvatarView: UIImageView, UIComposable {}

struct ProfileView: View {
	var body: some View {
		AvatarView().composable { avatarView in
			avatarView.image = UIImage(systemName: "person.circle.fill")
			avatarView.tintColor = .label
		}
	}
}
```

`UIComposable`과 `.composable(update:)`는 `@MainActor` API예요. UIKit 인스턴스 생성과 update는 main actor에서 수행해야 해요.

## Coordinator 연결

Delegate처럼 별도 객체가 필요한 UIKit 컴포넌트는 `UICoordinatedComposable`을 채택해요. 컴포넌트가 Coordinator 생성과 UIKit별 연결 방법을 소유하고 Bridge는 lifecycle 호출 순서만 관리해요.

```swift
import SwiftUI
import UIKit
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

### lifecycle

SwiftUI identity마다 `makeCoordinator()`가 한 번 호출돼요.

1. 최초 표시에서 `connect(coordinator:)`, 외부 `update`, `update(coordinator:)` 순으로 호출돼요.
2. 이후 갱신에서 실제로 표시 중인 UIKit 인스턴스에 외부 `update`를 적용한 뒤 같은 Coordinator로 `update(coordinator:)`를 호출해요.
3. identity가 사라질 때 실제로 표시 중인 UIKit 인스턴스와 같은 Coordinator로 `disconnect(coordinator:)`를 호출해요.

identity가 바뀌면 새 Coordinator가 생성될 수 있어요. 외부 `update`와 `update(coordinator:)`는 반복 호출에도 같은 결과를 내도록 구현해야 해요.

### 제네릭 제약

`composable(update:)`의 선택은 호출 지점의 정적 타입을 따라요. Coordinator lifecycle이 필요한 제네릭 함수는 `UICoordinatedComposable` 제약을 명시해야 해요.

```swift
@MainActor
func coordinatedView<T>(_ content: T) -> some View
where T: UIView & UICoordinatedComposable {
    content.composable()
}
```

`T: UIComposable`만 선언한 제네릭 함수는 기본 Bridge를 선택하므로 Coordinator lifecycle을 호출하지 않아요.
