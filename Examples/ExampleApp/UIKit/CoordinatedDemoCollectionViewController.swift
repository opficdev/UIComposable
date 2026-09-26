import SwiftUI
import UIComposable

@MainActor
final class CoordinatedDemoCollectionViewController: UICollectionViewController, UICoordinatedComposable {
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
        super.init(collectionViewLayout: DemoCollectionView.makeLayout())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = .secondarySystemBackground
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func connect(coordinator: Coordinator) {
        loadViewIfNeeded()
        let cellRegistration = DemoCollectionView.cellRegistration
        coordinator.diffableDataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
        collectionView.dataSource = coordinator.diffableDataSource
        collectionView.delegate = coordinator
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
        if collectionView.delegate === coordinator {
            collectionView.delegate = nil
        }
        if collectionView.dataSource === coordinator.diffableDataSource {
            collectionView.dataSource = nil
        }
        coordinator.diffableDataSource = nil
        coordinator.displayedItemsByCell.removeAll()
        coordinator.onSelection = nil
        coordinator.onWillDisplay = nil
        coordinator.onDidEndDisplaying = nil
    }
}
