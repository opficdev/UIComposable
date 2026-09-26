import SwiftUI

private enum ExampleRoute: Hashable {
    case basicCollectionView
    case fittingCollectionView
    case coordinatedCollectionView
    case fittingCoordinatedCollectionView
    case basicCollectionViewController
    case fittingCollectionViewController
    case coordinatedCollectionViewController
    case fittingCoordinatedCollectionViewController
}

struct ExampleIndexView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("UIView") {
                    NavigationLink("기본 CollectionView", value: ExampleRoute.basicCollectionView)
                    NavigationLink("크기 계산 CollectionView", value: ExampleRoute.fittingCollectionView)
                    NavigationLink("Coordinator CollectionView", value: ExampleRoute.coordinatedCollectionView)
                    NavigationLink(
                        "Coordinator 크기 계산 CollectionView",
                        value: ExampleRoute.fittingCoordinatedCollectionView
                    )
                }

                Section("UIViewController") {
                    NavigationLink(
                        "기본 CollectionViewController",
                        value: ExampleRoute.basicCollectionViewController
                    )
                    NavigationLink(
                        "크기 계산 CollectionViewController",
                        value: ExampleRoute.fittingCollectionViewController
                    )
                    NavigationLink(
                        "Coordinator CollectionViewController",
                        value: ExampleRoute.coordinatedCollectionViewController
                    )
                    NavigationLink(
                        "Coordinator 크기 계산 CollectionViewController",
                        value: ExampleRoute.fittingCoordinatedCollectionViewController
                    )
                }
            }
            .navigationTitle("UIComposable 예제")
            .navigationDestination(for: ExampleRoute.self) { route in
                switch route {
                case .basicCollectionView:
                    BasicCollectionViewDemo()
                case .fittingCollectionView:
                    FittingCollectionViewDemo()
                case .coordinatedCollectionView:
                    CoordinatedCollectionViewDemo()
                case .fittingCoordinatedCollectionView:
                    FittingCoordinatedCollectionViewDemo()
                case .basicCollectionViewController:
                    BasicCollectionViewControllerDemo()
                case .fittingCollectionViewController:
                    FittingCollectionViewControllerDemo()
                case .coordinatedCollectionViewController:
                    CoordinatedCollectionViewControllerDemo()
                case .fittingCoordinatedCollectionViewController:
                    FittingCoordinatedCollectionViewControllerDemo()
                }
            }
        }
    }
}
