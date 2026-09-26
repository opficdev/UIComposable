import SwiftUI
import UIComposable

struct FittingCoordinatedCollectionViewDemo: View {
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
                        Text("크기를 계산한 컬렉션에서도 항목 선택이 SwiftUI에 전달됩니다.")
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
                    CoordinatedDemoCollectionView
                        .composable(
                            update: { collectionView in
                                collectionView.isScrollEnabled = false
                                collectionView.items = Array(1...itemCount)
                                collectionView.onSelection = { selectedItem = $0 }
                                collectionView.onWillDisplay = { displayedItem = $0 }
                                collectionView.onDidEndDisplaying = { endedDisplayingItem = $0 }
                            },
                            sizeThatFits: { proposal, collectionView in
                                guard let width = proposal.width, 0 < width else {
                                    return nil
                                }

                                return CGSize(
                                    width: width,
                                    height: CollectionLayoutMetrics.height(
                                        for: width,
                                        itemCount: collectionView.items.count
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
        .navigationTitle("UIView Coordinator 크기 계산")
        .navigationBarTitleDisplayMode(.inline)
    }
}
