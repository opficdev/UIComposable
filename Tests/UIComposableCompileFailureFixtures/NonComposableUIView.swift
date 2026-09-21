import SwiftUI
import UIComposable

@MainActor
func UIComposable을_채택하지_않은_UIView는_composable을_사용할_수_없다() {
    _ = UIView().composable()
}
