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

    /// Async analyzes the provided audio and renders a DSImage of the waveform data calculated by the analyzer.
    /// - Parameter fromAudioAt: local filesystem URL of the audio file to process.
    /// - Parameter with: `Waveform.Configuration` to be used.
    /// - Parameter renderer: optional `WaveformRenderer` to adapt how the waveform shall be rendered.
    /// - Parameter qos: QoS of the DispatchQueue the calculations are performed (and returned) on.
    ///
    /// Returns the image on a background thread.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: Waveform.Configuration,
                              renderer: WaveformRenderer = LinearWaveformRenderer(),
                              position: Waveform.Position = .middle,
                              qos: DispatchQoS.QoSClass = .userInitiated) async throws -> DSImage {
        try await render(fromAudioAt: audioAssetURL, with: configuration, renderer: renderer, qos: qos, position: position)
    }

    /// Async analyzes the provided audio and renders a DSImage of the waveform data calculated by the analyzer.
    /// - Parameter fromAudioAt: local filesystem URL of the audio file to process.
    /// - Parameter with: `Waveform.Configuration` to be used.
    /// - Parameter renderer: optional `WaveformRenderer` to adapt how the waveform shall be rendered.
    /// - Parameter qos: QoS of the DispatchQueue the calculations are performed (and returned) on.
    /// - Parameter completionHandler: called from a background thread. Returns the sampled result `DSImage` or `Error`.
    ///
    /// Calls the completionHandler on a background thread.
    @available(*, deprecated, renamed: "waveformImage(fromAudioAt:with:renderer:qos:)")
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: Waveform.Configuration,
                              renderer: WaveformRenderer = LinearWaveformRenderer(),
                              qos: DispatchQoS.QoSClass = .userInitiated,
                              position: Waveform.Position = .middle,
                              completionHandler: @escaping (Result<DSImage, Error>) -> ()) {
        Task {
            do {
                let image = try await render(fromAudioAt: audioAssetURL, with: configuration, renderer: renderer, qos: qos, position: position)
                completionHandler(.success(image))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
}

extension WaveformImageDrawer {
    /// Renders the waveform from the provided samples into the provided `CGContext`.
    ///
    /// Samples need to be normalized within interval `(0...1)`.
    /// Ensure context size & scale match with the configuration's size & scale.
    public func draw(waveform samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, renderer: WaveformRenderer, position: Waveform.Position = .middle) {
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
        let dampedSamples = configuration.shouldDamp ? damp(clippedSamples, with: configuration) : clippedSamples
        let paddedSamples = shouldDrawSilencePadding ? Array(repeating: 1, count: samplesNeeded - clippedSamples.count) + dampedSamples : dampedSamples
        
        draw(on: context, from: paddedSamples, with: configuration, renderer: renderer, position: position)
    }

    func draw(on context: CGContext, from samples: [Float], with configuration: Waveform.Configuration, renderer: WaveformRenderer, position: Waveform.Position = .middle) {
        context.setAllowsAntialiasing(configuration.shouldAntialias)
        context.setShouldAntialias(configuration.shouldAntialias)
        context.setAlpha(1.0)

        drawBackground(on: context, with: configuration)
        renderer.render(samples: samples, on: context, with: configuration, lastOffset: lastOffset, position: position)
    }

    /// Damp the samples for a smoother animation.
    func damp(_ samples: [Float], with configuration: Waveform.Configuration) -> [Float] {
        guard let damping = configuration.damping, damping.percentage > 0 else {
            return samples
        }

        let count = Float(samples.count)
        return samples.enumerated().map { x, value -> Float in
            1 - ((1 - value) * dampFactor(x: Float(x), count: count, with: damping))
        }
    }
}

// MARK: Image generation

private extension WaveformImageDrawer {
    func render(
        fromAudioAt audioAssetURL: URL,
        with configuration: Waveform.Configuration,
        renderer: WaveformRenderer,
        qos: DispatchQoS.QoSClass,
        position: Waveform.Position
    ) async throws -> DSImage {
        let sampleCount = Int(configuration.size.width * configuration.scale)
        let waveformAnalyzer = WaveformAnalyzer()
        let samples = try await waveformAnalyzer.samples(fromAudioAt: audioAssetURL, count: sampleCount, qos: qos)
        let dampedSamples = configuration.shouldDamp ? self.damp(samples, with: configuration) : samples

        if let image = waveformImage(from: dampedSamples, with: configuration, renderer: renderer, position: position) {
            return image
        } else {
            throw GenerationError.generic
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

    private func dampFactor(x: Float, count: Float, with damping: Waveform.Damping) -> Float {
        if (damping.sides == .left || damping.sides == .both) && x < count * damping.percentage {
            // increasing linear damping within the left 8th (default)
            // basically (x : 1/8) with x in (0..<1/8)
            return damping.easing(x / (count * damping.percentage))
        } else if (damping.sides == .right || damping.sides == .both) && x > ((1 / damping.percentage) - 1) * (count * damping.percentage) {
            // decaying linear damping within the right 8th
            // basically also (x : 1/8), but since x in (7/8>...1) x is "inverted" as x = x - 7/8
            return damping.easing(1 - (x - (((1 / damping.percentage) - 1) * (count * damping.percentage))) / (count * damping.percentage))
        }
        return 1
    }
}
