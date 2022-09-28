import Foundation
import AVFoundation
import CoreGraphics

/// Renders a DSImage of the waveform data calculated by the analyzer.
public class WaveformImageDrawer: ObservableObject {
    public enum GenerationError: Error { case generic }

    public init() {}

    /// only internal; determines whether to draw silence lines in live mode.
    public var shouldDrawSilencePadding: Bool = false

    /// Makes sure we always look at the same samples while animating
    private var lastOffset: Int = 0

    /// Keep track of how many samples we are adding each draw cycle
    private var lastSampleCount: Int = 0

#if compiler(>=5.5) && canImport(_Concurrency)
    /// Async analyzes the provided audio and renders a DSImage of the waveform data calculated by the analyzer.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: Waveform.Configuration,
                              renderer: WaveformRenderer = LinearWaveformRenderer(),
                              qos: DispatchQoS.QoSClass = .userInitiated) async throws -> DSImage {
        try await withCheckedThrowingContinuation { continuation in
            waveformImage(fromAudioAt: audioAssetURL, with: configuration, renderer: renderer, qos: qos) { waveformImage in
                if let waveformImage = waveformImage {
                    continuation.resume(with: .success(waveformImage))
                } else {
                    continuation.resume(with: .failure(GenerationError.generic))
                }
            }
        }
    }
#endif

    /// Async analyzes the provided audio and renders a DSImage of the waveform data calculated by the analyzer.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: Waveform.Configuration,
                              renderer: WaveformRenderer = LinearWaveformRenderer(),
                              qos: DispatchQoS.QoSClass = .userInitiated,
                              completionHandler: @escaping (_ waveformImage: DSImage?) -> ()) {
        guard let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioAssetURL) else {
            completionHandler(nil)
            return
        }
        render(from: waveformAnalyzer, with: configuration, qos: qos, renderer: renderer, completionHandler: completionHandler)
    }
}

extension WaveformImageDrawer {
    /// Renders the waveform from the provided samples into the provided `CGContext`.
    ///
    /// Samples need to be normalized within interval `(0...1)`.
    /// Ensure context size & scale match with the configuration's size & scale.
    public func draw(waveform samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, renderer: WaveformRenderer) {
        guard samples.count > 0 || shouldDrawSilencePadding else {
            return
        }

        let samplesNeeded = Int(configuration.size.width * configuration.scale)

        let newSampleCount: Int = lastSampleCount > samples.count
            ? samples.count // this implies that we have reset drawing an are starting over
            : samples.count - lastSampleCount

        lastSampleCount = samples.count
        
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
        
        draw(on: context, from: paddedSamples, with: configuration, renderer: renderer)
    }

    func draw(on context: CGContext, from samples: [Float], with configuration: Waveform.Configuration, renderer: WaveformRenderer) {
        context.setAllowsAntialiasing(configuration.shouldAntialias)
        context.setShouldAntialias(configuration.shouldAntialias)
        context.setAlpha(1.0)

        drawBackground(on: context, with: configuration)
        renderer.render(samples: samples, on: context, with: configuration, lastOffset: lastOffset)
        renderer.style(context: context, with: configuration)
    }

    /// Dampen the samples for a smoother animation.
    func dampen(_ samples: [Float], with configuration: Waveform.Configuration) -> [Float] {
        guard let dampening = configuration.dampening, dampening.percentage > 0 else {
            return samples
        }

        let count = Float(samples.count)
        return samples.enumerated().map { x, value -> Float in
            1 - ((1 - value) * dampFactor(x: Float(x), count: count, with: dampening))
        }
    }
}

// MARK: Image generation

private extension WaveformImageDrawer {
    func render(from waveformAnalyzer: WaveformAnalyzer,
                with configuration: Waveform.Configuration,
                qos: DispatchQoS.QoSClass,
                renderer: WaveformRenderer,
                completionHandler: @escaping (_ waveformImage: DSImage?) -> ()) {
        let sampleCount = Int(configuration.size.width * configuration.scale)
        waveformAnalyzer.samples(count: sampleCount, qos: qos) { samples in
            guard let samples = samples else {
                completionHandler(nil)
                return
            }
            let dampenedSamples = configuration.shouldDampen ? self.dampen(samples, with: configuration) : samples
            completionHandler(self.waveformImage(from: dampenedSamples, with: configuration, renderer: renderer))
        }
    }

    private func drawBackground(on context: CGContext, with configuration: Waveform.Configuration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
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
