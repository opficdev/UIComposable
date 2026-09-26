import SwiftUI

enum CollectionLayoutMetrics {
    static let itemHeight: CGFloat = 72
    static let spacing: CGFloat = 8
    static let inset: CGFloat = 8

    static func columns(for width: CGFloat) -> Int {
        width < 300 ? 2 : 3
    }

    static func itemWidth(for width: CGFloat) -> CGFloat {
        let columns = columns(for: width)
        let contentWidth = width - inset * 2
        let totalSpacing = CGFloat(columns - 1) * spacing

        return max(1, (contentWidth - totalSpacing) / CGFloat(columns))
    }

    static func height(for width: CGFloat, itemCount: Int) -> CGFloat {
        let columns = columns(for: width)
        let rows = (itemCount + columns - 1) / columns
        let rowSpacing = CGFloat(max(0, rows - 1)) * spacing

        return CGFloat(rows) * itemHeight + rowSpacing + inset * 2
    }
}
