import SwiftUI

struct ExampleIndexView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("UIView") {
                    NavigationLink("기본 CollectionView") {
                        BasicCollectionViewDemo()
                    }
                    NavigationLink("크기 계산 CollectionView") {
                        FittingCollectionViewDemo()
                    }
                    NavigationLink("Coordinator CollectionView") {
                        CoordinatedCollectionViewDemo()
                    }
                    NavigationLink("Coordinator 크기 계산 CollectionView") {
                        FittingCoordinatedCollectionViewDemo()
                    }
                }

                Section("UIViewController") {
                    NavigationLink("기본 CollectionViewController") {
                        BasicCollectionViewControllerDemo()
                    }
                    NavigationLink("크기 계산 CollectionViewController") {
                        FittingCollectionViewControllerDemo()
                    }
                }
            }
            .navigationTitle("UIComposable 예제")
        }
    }
}
