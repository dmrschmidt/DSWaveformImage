import Foundation
import UIKit

typealias MyStyleDrawer = (
    _ samples: [Float],
    _ context: CGContext,
    _ configuration: WaveformConfiguration
) -> Void

protocol StyleDrawer {
    func drawGraph(from samples: [Float],
                   on context: CGContext,
                   with configuration: WaveformConfiguration)
}

extension WaveformStyle {
    var drawer: StyleDrawer {
        switch self {
        case .bubbled: return BubbleStyleDrawer()
        default: return LinearStyleDrawer()
        }
    }
}
