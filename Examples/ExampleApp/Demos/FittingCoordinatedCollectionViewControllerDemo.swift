import SwiftUI
import UIComposable

struct FittingCoordinatedCollectionViewControllerDemo: View {
    @State private var itemCount = 7
    @State private var width = 260.0
    @State private var selectedItem: Int?
    @State private var displayedItem: Int?
    @State private var endedDisplayingItem: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DemoRegion(.swiftUI) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("컨트롤러의 크기 계산과 선택 전달을 함께 확인합니다.")
                        Stepper("항목 \(itemCount)개", value: $itemCount, in: 1...12)
                        Slider(value: $width, in: 200...340) {
                            Text("컬렉션 폭")
                        }
                        Text("컬렉션 폭 \(Int(width))pt")
                        Text("선택: \(selectedItem.map(String.init) ?? "없음")")
                        Text("최근 표시 시작: \(displayedItem.map(String.init) ?? "없음")")
                        Text("최근 표시 종료: \(endedDisplayingItem.map(String.init) ?? "없음")")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DemoRegion(.uiKit) {
                    CoordinatedDemoCollectionViewController()
                        .composable(
                            update: { viewController in
                                viewController.collectionView.isScrollEnabled = false
                                viewController.items = Array(1...itemCount)
                                viewController.onSelection = { selectedItem = $0 }
                                viewController.onWillDisplay = { displayedItem = $0 }
                                viewController.onDidEndDisplaying = { endedDisplayingItem = $0 }
                            },
                            sizeThatFits: { proposal, viewController in
                                guard let width = proposal.width, 0 < width else {
                                    return nil
                                }

                                return CGSize(
                                    width: width,
                                    height: CollectionLayoutMetrics.height(
                                        for: width,
                                        itemCount: viewController.items.count
                                    )
                                )
                            }
                        )
                        .frame(width: CGFloat(width))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("UIViewController Coordinator 크기 계산")
        .navigationBarTitleDisplayMode(.inline)
    }
}
