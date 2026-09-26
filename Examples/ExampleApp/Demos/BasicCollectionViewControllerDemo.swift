import SwiftUI
import UIComposable

struct BasicCollectionViewControllerDemo: View {
    @State private var itemCount = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoRegion(.swiftUI) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SwiftUI의 항목 수를 바꾸면 표시 중인 UICollectionViewController가 갱신됩니다.")
                    Stepper("항목 \(itemCount)개", value: $itemCount, in: 1...12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DemoRegion(.uiKit) {
                    DemoCollectionViewController
                    .composable { viewController in
                        viewController.applyItems(Array(1...itemCount))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("UIViewController 기본")
        .navigationBarTitleDisplayMode(.inline)
    }
}
