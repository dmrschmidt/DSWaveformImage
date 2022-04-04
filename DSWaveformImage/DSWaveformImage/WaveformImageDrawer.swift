import Foundation
import AVFoundation
import UIKit
import CoreGraphics

/// Renders a UIImage of the waveform data calculated by the analyzer.
public class WaveformImageDrawer {
    public enum GenerationError: Error { case generic }

    public init() {}

    /// only internal; determines whether to draw silence lines in live mode.
    var shouldDrawSilencePadding: Bool = false

    /// Makes sure we always look at the same samples while animating
    private var lastOffset: Int = 0

#if compiler(>=5.5) && canImport(_Concurrency)
    /// Async analyzes the provided audio and renders a UIImage of the waveform data calculated by the analyzer.
    @available(iOS 13, *)
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: Waveform.Configuration,
                              qos: DispatchQoS.QoSClass = .userInitiated) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            waveformImage(fromAudioAt: audioAssetURL, with: configuration, qos: qos) { waveformImage in
                if let waveformImage = waveformImage {
                    continuation.resume(with: .success(waveformImage))
                } else {
                    continuation.resume(with: .failure(GenerationError.generic))
                }
            }
        }
    }
#endif

    /// Async analyzes the provided audio and renders a UIImage of the waveform data calculated by the analyzer.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: Waveform.Configuration,
                              qos: DispatchQoS.QoSClass = .userInitiated,
                              completionHandler: @escaping (_ waveformImage: UIImage?) -> ()) {
        guard let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioAssetURL) else {
            completionHandler(nil)
            return
        }
        render(from: waveformAnalyzer, with: configuration, qos: qos, completionHandler: completionHandler)
    }

    /// Renders a UIImage of the provided waveform samples.
    ///
    /// Samples need to be normalized within interval `(0...1)`.
    public func waveformImage(from samples: [Float], with configuration: Waveform.Configuration) -> UIImage? {
        guard samples.count > 0, samples.count == Int(configuration.size.width * configuration.scale) else {
            print("ERROR: samples: \(samples.count) != \(configuration.size.width) * \(configuration.scale)")
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        let renderer = UIGraphicsImageRenderer(size: configuration.size, format: format)
        let dampenedSamples = configuration.shouldDampen ? dampen(samples, with: configuration) : samples

        return renderer.image { renderContext in
            draw(on: renderContext.cgContext, from: dampenedSamples, with: configuration)
        }
    }
}

extension WaveformImageDrawer {
    /// Renders the waveform from the provided samples into the provided `CGContext`.
    ///
    /// Samples need to be normalized within interval `(0...1)`.
    /// Ensure context size & scale match with the configuration's size & scale.
    func draw(waveform samples: [Float], newSampleCount: Int, on context: CGContext, with configuration: Waveform.Configuration) {
        guard samples.count > 0 || shouldDrawSilencePadding else {
            return
        }

        let samplesNeeded = Int(configuration.size.width * configuration.scale)
        
        // Reset the cumulative lastOffset when new drawing begins
        if samples.count == newSampleCount {
            lastOffset = 0
        }

        if case .striped = configuration.style {
            if shouldDrawSilencePadding {
                lastOffset = (lastOffset + newSampleCount) % stripeBucket(configuration)
            } else if samples.count >= samplesNeeded {
                lastOffset = (lastOffset + min(newSampleCount, samples.count - samplesNeeded)) % stripeBucket(configuration)
            }
        }

        // move the window, so that its always at the end (appears to move from right to left)
        let startSample = max(0, samples.count - samplesNeeded)
        let clippedSamples = Array(samples[startSample..<samples.count])
        let dampenedSamples = configuration.shouldDampen ? dampen(clippedSamples, with: configuration) : clippedSamples
        let paddedSamples = shouldDrawSilencePadding ? Array(repeating: 1, count: samplesNeeded - clippedSamples.count) + dampenedSamples : dampenedSamples
        
        draw(on: context, from: paddedSamples, with: configuration)
    }
}

// MARK: Image generation

private extension WaveformImageDrawer {
    func render(from waveformAnalyzer: WaveformAnalyzer,
                with configuration: Waveform.Configuration,
                qos: DispatchQoS.QoSClass,
                completionHandler: @escaping (_ waveformImage: UIImage?) -> ()) {
        let sampleCount = Int(configuration.size.width * configuration.scale)
        waveformAnalyzer.samples(count: sampleCount, qos: qos) { samples in
            guard let samples = samples else {
                completionHandler(nil)
                return
            }
            let dampenedSamples = configuration.shouldDampen ? self.dampen(samples, with: configuration) : samples
            completionHandler(self.waveformImage(from: dampenedSamples, with: configuration))
        }
    }

    private func draw(on context: CGContext, from samples: [Float], with configuration: Waveform.Configuration) {
        context.setAllowsAntialiasing(configuration.shouldAntialias)
        context.setShouldAntialias(configuration.shouldAntialias)

        drawBackground(on: context, with: configuration)
        drawGraph(from: samples, on: context, with: configuration)
    }

    private func drawBackground(on context: CGContext, with configuration: Waveform.Configuration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
    }

    private func drawGraph(from samples: [Float],
                           on context: CGContext,
                           with configuration: Waveform.Configuration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let positionAdjustedGraphCenter = CGFloat(configuration.position.value()) * graphRect.size.height
        let drawMappingFactor = graphRect.size.height * configuration.verticalScalingFactor
        let minimumGraphAmplitude: CGFloat = 1 / configuration.scale // we want to see at least a 1px line for silence

        let path = CGMutablePath()
        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'

        for (y, sample) in samples.enumerated() {
            let x = y + lastOffset
            if case .striped = configuration.style, x % Int(configuration.scale) != 0 || x % stripeBucket(configuration) != 0 {
                // skip sub-pixels - any x value not scale aligned
                // skip any point that is not a multiple of our bucket width (width + spacing)
                continue
            }

            let samplesNeeded = Int(configuration.size.width * configuration.scale)
            let xOffset = CGFloat(samplesNeeded - samples.count) / configuration.scale // When there's extra space, draw waveform on the right
            let xPos = (CGFloat(x - lastOffset) / configuration.scale) + xOffset
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
            maxAmplitude = max(drawingAmplitude, maxAmplitude)

            path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
            path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
        }

        context.addPath(path)
        context.setAlpha(1.0)
        context.setShouldAntialias(configuration.shouldAntialias)

        if case let .striped(config) = configuration.style {
            // draw scale-perfect for striped waveforms
            context.setLineWidth(config.width)
        } else {
            // draw pixel-perfect for filled waveforms
            context.setLineWidth(1.0 / configuration.scale)
        }

        switch configuration.style {
        case let .filled(color):
            context.setStrokeColor(color.cgColor)
            context.strokePath()
        case let .striped(config):
            context.setLineCap(config.lineCap)
            context.setStrokeColor(config.color.cgColor)
            context.strokePath()
        case let .gradient(colors):
            context.replacePathWithStrokedPath()
            context.clip()
            let colors = NSArray(array: colors.map(\.cgColor)) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: positionAdjustedGraphCenter - maxAmplitude),
                                       end: CGPoint(x: 0, y: positionAdjustedGraphCenter + maxAmplitude),
                                       options: .drawsAfterEndLocation)
        }
    }
}

// MARK: - Helpers

private extension WaveformImageDrawer {
    private func stripeCount(_ configuration: Waveform.Configuration) -> Int {
        if case .striped = configuration.style {
            return Int(configuration.size.width * configuration.scale) / stripeBucket(configuration)
        } else {
            return 0
        }
    }

    private func stripeBucket(_ configuration: Waveform.Configuration) -> Int {
        if case let .striped(stripeConfig) = configuration.style {
            return Int(stripeConfig.width + stripeConfig.spacing) * Int(configuration.scale)
        } else {
            return 0
        }
    }

    /// Dampen the samples for a smoother animation.
    private func dampen(_ samples: [Float], with configuration: Waveform.Configuration) -> [Float] {
        guard let dampening = configuration.dampening, dampening.percentage > 0 else {
            return samples
        }

        let count = Float(samples.count)
        return samples.enumerated().map { x, value -> Float in
            1 - ((1 - value) * dampFactor(x: Float(x), count: count, with: dampening))
        }
    }

    private func dampFactor(x: Float, count: Float, with dampening: Waveform.Dampening) -> Float {
        if (dampening.sides == .left || dampening.sides == .both) && x < count * dampening.percentage {
            // increasing linear dampening within the left 8th (default)
            // basically (x : 1/8) with x in (0..<1/8)
            return dampening.easing(x / (count * dampening.percentage))
        } else if (dampening.sides == .right || dampening.sides == .both) && x > ((1 / dampening.percentage) - 1) * (count * dampening.percentage) {
            // decaying linear dampening within the right 8th
            // basically also (x : 1/8), but since x in (7/8>...1) x is "inverted" as x = x - 7/8
            return dampening.easing(1 - (x - (((1 / dampening.percentage) - 1) * (count * dampening.percentage))) / (count * dampening.percentage))
        }
        return 1
    }
}
