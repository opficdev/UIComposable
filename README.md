<h1 align="center">UIComposable</h1>

<p align="center">
  UIKit 인스턴스를 SwiftUI의 .composable(update:)로 표시해요.
</p>

<p align="center">
  <a href="#설치">설치</a>
  <a href="#첫-composable">첫 composable</a>
  <a href="#크기-계산">크기 계산</a>
  <a href="#coordinator-연결">Coordinator 연결</a>
  <a href="#예제-앱">예제 앱</a>
  <a href="LICENSE">MIT License</a>
</p>

<br />

UIComposable은 `UIView`와 `UIViewController` 인스턴스를 SwiftUI 화면에 연결해요. 기본 Bridge는 외부 `update`만 적용하고, Delegate처럼 별도 객체가 필요한 경우에는 `UICoordinatedComposable`이 Coordinator lifecycle을 관리해요.

iOS 17 이상과 Swift 6 이상이 필요해요.

## 설치

UIComposable은 Swift Package Manager에서 설치해요. 아래 `sizeThatFits:` 예제를 사용하려면 `0.2.0`이 필요해요. `0.x.y`에서는 minor version이 호환성을 보장하지 않으므로 `Up to Next Minor Version`으로 `0.2.x` 범위의 업데이트를 받아요.

Xcode에서는 File > Add Package Dependencies...를 선택하고 아래 URL을 입력해요. Dependency Rule은 Up to Next Minor Version, 버전은 `0.2.0`으로 설정해요.

```
https://github.com/opficdev/UIComposable.git
```

`Package.swift`에서는 다음 dependency와 product를 target에 추가해요.

```swift
dependencies: [
	.package(
		url: "https://github.com/opficdev/UIComposable.git",
		.upToNextMinor(from: "0.2.0")
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

재현 가능한 build가 필요하면 Dependency Rule을 **Exact Version**으로 설정하거나 `Package.swift`의 dependency를 `.exact("0.2.0")`으로 바꿔요.

## 첫 composable

`UIComposable`을 채택한 `UIView` 또는 `UIViewController`에서 `.composable(update:)`를 호출해요. SwiftUI가 다시 그릴 때마다 실제로 표시 중인 UIKit 인스턴스에 `update`가 적용돼요. 아래 코드는 [ExampleApp의 기본 CollectionView 예제](Examples/ExampleApp/Demos/BasicCollectionViewDemo.swift)에서 핵심 호출을 발췌했어요. `DemoCollectionView`는 예제 앱에서 정의한 타입이며 [구현 코드](Examples/ExampleApp/UIKit/DemoCollectionView.swift)를 함께 볼 수 있어요.

```swift
import SwiftUI
import UIComposable

struct BasicCollectionViewDemo: View {
	@State private var itemCount = 6

	var body: some View {
		DemoCollectionView()
			.composable { collectionView in
				collectionView.applyItems(Array(1...itemCount))
			}
			.frame(height: 280)
	}
}
```

`UIComposable`과 `.composable(update:)`는 `@MainActor` API예요. UIKit 인스턴스 생성과 update는 main actor에서 수행해야 해요.

## 크기 계산

`sizeThatFits:`를 지정하면 SwiftUI가 제안한 크기와 실제로 표시 중인 UIKit 인스턴스를 받아 필요한 크기를 반환할 수 있어요. 지정하지 않으면 Bridge는 `nil`을 반환하고 SwiftUI의 기본 크기 계산을 유지해요.

아래 [CollectionView 크기 계산 예제](Examples/ExampleApp/Demos/FittingCollectionViewDemo.swift)는 제안된 폭과 항목 수로 전체 높이를 계산해요. 폭이 없으면 `nil`을 반환하므로 SwiftUI가 기본 방식으로 크기를 계산해요. 배치와 높이 계산은 같은 [CollectionLayoutMetrics](Examples/ExampleApp/Support/CollectionLayoutMetrics.swift)를 사용해요. 다음 코드는 해당 화면의 크기 계산 호출을 발췌했어요.

```swift
import SwiftUI
import UIComposable

struct FittingCollectionViewDemo: View {
	@State private var itemCount = 7
	@State private var width = 260.0

	var body: some View {
		DemoCollectionView()
			.composable(
				update: { collectionView in
					collectionView.isScrollEnabled = false
					collectionView.applyItems(Array(1...itemCount))
				},
				sizeThatFits: { proposal, collectionView in
					guard let width = proposal.width, 0 < width else {
						return nil
					}

					return CGSize(
						width: width,
						height: CollectionLayoutMetrics.height(
							for: width,
							itemCount: collectionView.itemCount
						)
					)
				}
			)
			.frame(width: CGFloat(width))
	}
}
```

`sizeThatFits:`는 SwiftUI의 배치 과정에서 반복 호출될 수 있어요. 크기 계산만 수행하고 상태를 바꾸지 않아야 해요. Coordinator lifecycle과도 별도로 호출돼요.

## Coordinator 연결

Delegate처럼 별도 객체가 필요한 UIKit 컴포넌트는 `UICoordinatedComposable`을 채택해요. 컴포넌트가 Coordinator 생성과 UIKit별 연결 방법을 소유하고 Bridge는 lifecycle 호출 순서만 관리해요. [ExampleApp의 CoordinatedDemoCollectionView](Examples/ExampleApp/UIKit/CoordinatedDemoCollectionView.swift)는 Coordinator에서 `dataSource`와 `delegate`를 연결하고 선택 결과와 셀 표시 생명주기를 SwiftUI에 전달해요. 다음 코드는 [해당 화면](Examples/ExampleApp/Demos/CoordinatedCollectionViewDemo.swift)의 호출을 발췌했어요.

```swift
import SwiftUI
import UIComposable

struct CoordinatedCollectionViewDemo: View {
	@State private var itemCount = 18
	@State private var selectedItem: Int?
	@State private var displayedItem: Int?
	@State private var endedDisplayingItem: Int?

	var body: some View {
		CoordinatedDemoCollectionView()
			.composable { collectionView in
				collectionView.items = Array(1...itemCount)
				collectionView.onSelection = { selectedItem = $0 }
				collectionView.onWillDisplay = { displayedItem = $0 }
				collectionView.onDidEndDisplaying = { endedDisplayingItem = $0 }
			}
			.frame(height: 280)
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
where T: UICollectionView & UICoordinatedComposable {
    content.composable()
}
```

`T: UIComposable`만 선언한 제네릭 함수는 기본 Bridge를 선택하므로 Coordinator lifecycle을 호출하지 않아요.

## 예제 앱

[ExampleApp](Examples/ExampleApp/ExampleApp.xcodeproj)은 `UICollectionView`와 `UICollectionViewController`의 기본, 크기 계산, Coordinator, Coordinator와 크기 계산 경로를 각각 보여줘요. 모두 여덟 화면이며 저장소의 `UIComposable` 패키지를 상대 경로로 사용해요.

Xcode에서 `Examples/ExampleApp/ExampleApp.xcodeproj`를 열고 `ExampleApp` scheme과 iOS Simulator를 선택해 실행할 수 있어요. 실행 없이 빌드만 확인하려면 저장소 루트에서 다음 명령을 사용해요.

```bash
xcodebuild -project Examples/ExampleApp/ExampleApp.xcodeproj \
	-scheme ExampleApp \
	-configuration Debug \
	-destination 'generic/platform=iOS Simulator' \
	CODE_SIGNING_ALLOWED=NO build
```

기본 화면에서는 항목 수를 바꿔 갱신을 확인하고, 크기 계산 화면에서는 폭을 조절해 높이 변화를 확인해요. Coordinator 화면에서는 항목 선택과 셀 표시 시작 및 종료가 SwiftUI 상태로 전달되는지 확인해요.
