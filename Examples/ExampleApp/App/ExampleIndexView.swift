import SwiftUI

struct ExampleIndexView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("UIView") {
                    NavigationLink("기본 CollectionView") {
                        BasicCollectionViewDemo()
                    }
                }
            }
            .navigationTitle("UIComposable 예제")
        }
    }
}
