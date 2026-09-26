import SwiftUI
import UIComposable

struct CoordinatedCollectionViewControllerDemo: View {
    @State private var itemCount = 18
    @State private var selectedItem: Int?
    @State private var displayedItem: Int?
    @State private var endedDisplayingItem: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            DemoRegion(.swiftUI) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("컨트롤러의 항목을 선택하거나 스크롤해 셀 표시 생명주기를 확인해 보세요.")
                    Stepper("항목 \(itemCount)개", value: $itemCount, in: 8...30)
                    Text("선택: \(selectedItem.map(String.init) ?? "없음")")
                    Text("최근 표시 시작: \(displayedItem.map(String.init) ?? "없음")")
                    Text("최근 표시 종료: \(endedDisplayingItem.map(String.init) ?? "없음")")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            DemoRegion(.uiKit) {
                    CoordinatedDemoCollectionViewController
                    .composable { viewController in
                        viewController.items = Array(1...itemCount)
                        viewController.onSelection = { selectedItem = $0 }
                        viewController.onWillDisplay = { displayedItem = $0 }
                        viewController.onDidEndDisplaying = { endedDisplayingItem = $0 }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("UIViewController Coordinator")
        .navigationBarTitleDisplayMode(.inline)
    }
}
