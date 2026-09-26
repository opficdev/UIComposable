import SwiftUI

enum DemoRegionKind {
    case swiftUI
    case uiKit

    var label: String {
        switch self {
        case .swiftUI:
            "SwiftUI 영역"
        case .uiKit:
            "UIKit 영역"
        }
    }

    var color: Color {
        switch self {
        case .swiftUI:
            .blue
        case .uiKit:
            .orange
        }
    }
}

struct DemoRegion<Content: View>: View {
    let kind: DemoRegionKind
    @ViewBuilder let content: Content

    init(_ kind: DemoRegionKind, @ViewBuilder content: () -> Content) {
        self.kind = kind
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        kind.color,
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            }
            .overlay(alignment: .topLeading) {
                Text(kind.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(kind.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.background, in: Capsule())
                    .offset(x: 12, y: -10)
            }
            .padding(.top, 8)
    }
}
