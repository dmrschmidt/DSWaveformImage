#if os(iOS) || swift(>=5.9) && os(visionOS)
import Foundation
import AVFoundation
import UIKit
import CoreGraphics

public extension WaveformImageDrawer {
    /// Renders a DSImage of the provided waveform samples.
    ///
    /// Samples need to be normalized within interval `(0...1)`.
    func waveformImage(from samples: [Float], with configuration: Waveform.Configuration, renderer: WaveformRenderer, position: Waveform.Position = .middle) -> DSImage? {
        guard samples.count > 0, samples.count == Int(configuration.size.width * configuration.scale) else {
            print("ERROR: samples: \(samples.count) != \(configuration.size.width) * \(configuration.scale)")
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        let imageRenderer = UIGraphicsImageRenderer(size: configuration.size, format: format)
        let dampedSamples = configuration.shouldDamp ? damp(samples, with: configuration) : samples

        return imageRenderer.image { renderContext in
            draw(on: renderContext.cgContext, from: dampedSamples, with: configuration, renderer: renderer, position: position)
        }
    }
}
#endif
