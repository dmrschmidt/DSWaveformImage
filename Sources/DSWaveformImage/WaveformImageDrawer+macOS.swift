#if os(macOS)
import Foundation
import AVFoundation
import AppKit
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

        let dampedSamples = configuration.shouldDamp ? damp(samples, with: configuration) : samples
        return NSImage(size: configuration.size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else {
                fatalError("Missing context")
            }
            self.draw(on: context, from: dampedSamples, with: configuration, renderer: renderer, position: position)
            return true
        }
    }
}
#endif
