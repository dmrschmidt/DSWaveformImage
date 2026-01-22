import Foundation
import CoreGraphics

/**
 Renders stereo audio with left and right channels displayed independently.
 
 The left channel is drawn in the top half and the right channel in the bottom half.
 Expects samples to be provided as: [left_samples..., right_samples...]
 */
public struct StereoWaveformRenderer: WaveformRenderer {
    private let baseRenderer: LinearWaveformRenderer
    
    public init() {
        self.baseRenderer = LinearWaveformRenderer()
    }
    
    public func path(samples: [Float], with configuration: Waveform.Configuration, lastOffset: Int, position: Waveform.Position = .middle) -> CGPath {
        let combinedPath = CGMutablePath()
        
        // Split samples into left and right channels
        let halfCount = samples.count / 2
        guard halfCount > 0 else { return combinedPath }
        
        let leftSamples = Array(samples[0..<halfCount])
        let rightSamples = Array(samples[halfCount..<samples.count])
        
        // Create configuration for half-height rendering
        let halfHeightConfig = configuration.with(size: CGSize(width: configuration.size.width, height: configuration.size.height / 2))
        
        // Render left channel in top half
        let leftPath = baseRenderer.path(samples: leftSamples, with: halfHeightConfig, lastOffset: lastOffset, position: .bottom)
        combinedPath.addPath(leftPath)
        
        // Render right channel in bottom half (offset vertically)
        let rightPath = baseRenderer.path(samples: rightSamples, with: halfHeightConfig, lastOffset: lastOffset, position: .top)
        
        // Translate the right channel path to the bottom half
        var transform = CGAffineTransform(translationX: 0, y: configuration.size.height / 2)
        if let translatedPath = rightPath.copy(using: &transform) {
            combinedPath.addPath(translatedPath)
        }
        
        return combinedPath
    }
    
    public func render(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int, position: Waveform.Position = .middle) {
        context.addPath(path(samples: samples, with: configuration, lastOffset: lastOffset, position: position))
        defaultStyle(context: context, with: configuration)
    }
}
