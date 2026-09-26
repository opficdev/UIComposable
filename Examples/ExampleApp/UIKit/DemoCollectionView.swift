import SwiftUI
import UIComposable

@MainActor
final class DemoCollectionView: UICollectionView, UIComposable {
    private static let cellRegistration = CellRegistration<UICollectionViewCell, Int> { cell, _, item in
        var content = UIListContentConfiguration.cell()
        content.text = "항목 \(item)"
        cell.contentConfiguration = content
        cell.backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    }

    private lazy var diffableDataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: self) {
        [cellRegistration = DemoCollectionView.cellRegistration] collectionView, indexPath, item in
        collectionView.dequeueConfiguredReusableCell(
            using: cellRegistration,
            for: indexPath,
            item: item
        )
    }

    private(set) var itemCount = 0

    init() {
        super.init(frame: .zero, collectionViewLayout: Self.makeLayout())
        backgroundColor = .secondarySystemBackground
        _ = diffableDataSource
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyItems(_ items: [Int]) {
        guard diffableDataSource.snapshot().itemIdentifiers != items else {
            return
        }

        itemCount = items.count
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columns = CollectionLayoutMetrics.columns(for: width)
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(CollectionLayoutMetrics.itemWidth(for: width)),
                heightDimension: .absolute(CollectionLayoutMetrics.itemHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(CollectionLayoutMetrics.itemHeight)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                repeatingSubitem: item,
                count: columns
            )
            group.interItemSpacing = .fixed(CollectionLayoutMetrics.spacing)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = CollectionLayoutMetrics.spacing
            section.contentInsets = NSDirectionalEdgeInsets(
                top: CollectionLayoutMetrics.inset,
                leading: CollectionLayoutMetrics.inset,
                bottom: CollectionLayoutMetrics.inset,
                trailing: CollectionLayoutMetrics.inset
            )
            return section
        }
    }
}
