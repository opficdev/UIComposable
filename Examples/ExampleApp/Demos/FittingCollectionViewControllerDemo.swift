import SwiftUI
import UIComposable

struct FittingCollectionViewControllerDemo: View {
    @State private var itemCount = 7
    @State private var width = 260.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DemoRegion(.swiftUI) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("컨트롤러의 컬렉션도 제안된 폭에 맞춰 전체 높이를 계산합니다.")
                        Stepper("항목 \(itemCount)개", value: $itemCount, in: 1...12)
                        Slider(value: $width, in: 200...340) {
                            Text("컬렉션 폭")
                        }
                        Text("컬렉션 폭 \(Int(width))pt")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                DemoRegion(.uiKit) {
                    DemoCollectionViewController
                        .composable(
                            update: { viewController in
                                viewController.applyItems(Array(1...itemCount))
                                viewController.collectionView.isScrollEnabled = false
                            },
                            sizeThatFits: { proposal, viewController in
                                guard let width = proposal.width, 0 < width else {
                                    return nil
                                }

                                return CGSize(
                                    width: width,
                                    height: CollectionLayoutMetrics.height(
                                        for: width,
                                        itemCount: viewController.itemCount
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
        .navigationTitle("UIViewController 크기 계산")
        .navigationBarTitleDisplayMode(.inline)
    }
}
