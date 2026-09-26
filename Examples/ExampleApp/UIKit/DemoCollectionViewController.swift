import SwiftUI
import UIComposable

@MainActor
final class DemoCollectionViewController: UICollectionViewController, UIComposable {
    private var diffableDataSource: UICollectionViewDiffableDataSource<Int, Int>?
    private(set) var itemCount = 0

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
        let cellRegistration = DemoCollectionView.cellRegistration
        diffableDataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
            collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
    }

    func applyItems(_ items: [Int]) {
        loadViewIfNeeded()
        guard diffableDataSource?.snapshot().itemIdentifiers != items else {
            return
        }

        itemCount = items.count
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }
}
