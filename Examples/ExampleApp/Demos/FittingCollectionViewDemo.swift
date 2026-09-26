import SwiftUI
import UIComposable

struct FittingCollectionViewDemo: View {
    @State private var itemCount = 7
    @State private var width = 260.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DemoRegion(.swiftUI) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("제안된 폭에 맞춰 열 수와 전체 높이를 계산합니다.")
                        Stepper("항목 \(itemCount)개", value: $itemCount, in: 1...12)
                        Slider(value: $width, in: 200...340) {
                            Text("컬렉션 폭")
                        }
                        Text("컬렉션 폭 \(Int(width))pt")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DemoRegion(.uiKit) {
                    DemoCollectionView
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
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("UIView 크기 계산")
        .navigationBarTitleDisplayMode(.inline)
    }
}
