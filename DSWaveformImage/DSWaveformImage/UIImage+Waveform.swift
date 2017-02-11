import Foundation
import UIKit

public extension UIImage {
    public convenience init?(waveform: Waveform, configuration: WaveformConfiguration) {
        let waveformImageDrawer = WaveformImageDrawer()
        guard let image = waveformImageDrawer.waveformImage(from: waveform, with: configuration)?.cgImage else {
            return nil
        }

        self.init(cgImage: image)
    }
}
