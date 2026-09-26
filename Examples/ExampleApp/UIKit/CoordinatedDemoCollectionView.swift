import SwiftUI
import UIComposable

@MainActor
final class CoordinatedDemoCollectionView: UICollectionView, UICoordinatedComposable {
    final class Coordinator: NSObject, UICollectionViewDelegate {
        var diffableDataSource: UICollectionViewDiffableDataSource<Int, Int>?
        var displayedItemsByCell: [ObjectIdentifier: Int] = [:]
        var onSelection: ((Int) -> Void)?
        var onWillDisplay: ((Int) -> Void)?
        var onDidEndDisplaying: ((Int) -> Void)?

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else {
                return
            }

            onSelection?(item)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
        ) {
            guard let item = diffableDataSource?.itemIdentifier(for: indexPath) else {
                return
            }

            displayedItemsByCell[ObjectIdentifier(cell)] = item
            onWillDisplay?(item)
        }

        func collectionView(
            _ collectionView: UICollectionView,
            didEndDisplaying cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath
        ) {
            guard let item = displayedItemsByCell.removeValue(forKey: ObjectIdentifier(cell)) else {
                return
            }

            onDidEndDisplaying?(item)
        }
    }

    var items: [Int] = []
    var onSelection: ((Int) -> Void)?
    var onWillDisplay: ((Int) -> Void)?
    var onDidEndDisplaying: ((Int) -> Void)?

    init() {
        super.init(frame: .zero, collectionViewLayout: DemoCollectionView.makeLayout())
        backgroundColor = .secondarySystemBackground
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func connect(coordinator: Coordinator) {
        let cellRegistration = DemoCollectionView.cellRegistration
        coordinator.diffableDataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: self) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
        dataSource = coordinator.diffableDataSource
        delegate = coordinator
    }

    func update(coordinator: Coordinator) {
        coordinator.onSelection = onSelection
        coordinator.onWillDisplay = onWillDisplay
        coordinator.onDidEndDisplaying = onDidEndDisplaying

        guard coordinator.diffableDataSource?.snapshot().itemIdentifiers != items else {
            return
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        coordinator.diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }

    func disconnect(coordinator: Coordinator) {
        if delegate === coordinator {
            delegate = nil
        }
        if dataSource === coordinator.diffableDataSource {
            dataSource = nil
        }
        coordinator.diffableDataSource = nil
        coordinator.displayedItemsByCell.removeAll()
        coordinator.onSelection = nil
        coordinator.onWillDisplay = nil
        coordinator.onDidEndDisplaying = nil
    }
}
