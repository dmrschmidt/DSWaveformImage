#if os(iOS)
import Foundation
import AVFoundation
import UIKit
import CoreGraphics

public extension WaveformImageDrawer {
    /// Renders a DSImage of the provided waveform samples.
    ///
    /// Samples need to be normalized within interval `(0...1)`.
    func waveformImage(from samples: [Float], with configuration: Waveform.Configuration, renderer: WaveformRenderer) -> DSImage? {
        guard samples.count > 0, samples.count == Int(configuration.size.width * configuration.scale) else {
            print("ERROR: samples: \(samples.count) != \(configuration.size.width) * \(configuration.scale)")
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        let imageRenderer = UIGraphicsImageRenderer(size: configuration.size, format: format)
        let dampenedSamples = configuration.shouldDampen ? dampen(samples, with: configuration) : samples

        return imageRenderer.image { renderContext in
            draw(on: renderContext.cgContext, from: dampenedSamples, with: configuration, renderer: renderer)
        }
    }
}
#endif
