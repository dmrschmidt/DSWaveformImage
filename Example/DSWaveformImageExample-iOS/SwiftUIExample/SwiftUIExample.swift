import Foundation
import UIKit
import SwiftUI

// This wrapper only exists to connect InterfaceBuilder & SwiftUI.
class SwiftUIExampleViewController: UIHostingController<SwiftUIExampleView> {
    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: SwiftUIExampleView())
    }
}
