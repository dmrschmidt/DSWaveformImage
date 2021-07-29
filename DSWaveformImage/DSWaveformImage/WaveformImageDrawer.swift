import Foundation
import AVFoundation
import UIKit
import CoreGraphics

/// Renders a UIImage of the waveform data calculated by the analyzer.
public class WaveformImageDrawer {
    public init() {}

    // swiftlint:disable function_parameter_count
    /// Renders a UIImage of the waveform data calculated by the analyzer.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              with configuration: WaveformConfiguration,
                              qos: DispatchQoS.QoSClass = .userInitiated,
                              completionHandler: @escaping (_ waveformImage: UIImage?) -> ()) {
        guard let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioAssetURL) else {
            completionHandler(nil)
            return
        }
        render(from: waveformAnalyzer, with: configuration, qos: qos, completionHandler: completionHandler)
    }

    /// Renders a UIImage of the waveform data calculated by the analyzer.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              size: CGSize,
                              backgroundColor: UIColor = UIColor.clear,
                              style: WaveformStyle = .gradient([UIColor.black, UIColor.darkGray]),
                              position: WaveformPosition = .middle,
                              scale: CGFloat = UIScreen.main.scale,
                              verticalScalingFactor: CGFloat = 0.95,
                              qos: DispatchQoS.QoSClass = .userInitiated,
                              shouldAntialias: Bool = false,
                              completionHandler: @escaping (_ waveformImage: UIImage?) -> ()) {
        let configuration = WaveformConfiguration(size: size, backgroundColor: backgroundColor, style: style, position: position,
                                                  scale: scale, verticalScalingFactor: verticalScalingFactor, shouldAntialias: shouldAntialias)
        waveformImage(fromAudioAt: audioAssetURL, with: configuration, completionHandler: completionHandler)
    }

    public func waveformImage(from samples: [Float], with configuration: WaveformConfiguration) -> UIImage? {
        guard samples.count > 0, samples.count == Int(configuration.size.width * configuration.scale) else {
            print("ERROR: samples: \(samples.count) != \(configuration.size.width) * \(configuration.scale)")
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        let renderer = UIGraphicsImageRenderer(size: configuration.size, format: format)

        return renderer.image { renderContext in
            draw(on: renderContext.cgContext, from: samples, with: configuration)
        }
    }

    public func waveformImage(from samples: [Float], with configuration: WaveformConfiguration, context: CGContext) {
        guard samples.count > 0 else {
            return
        }

        var clampedSamples = samples
        if case .striped = configuration.style {
            let stripeDivisableLeftover = samples.count % stripeCount(configuration)
            clampedSamples = Array(samples[0..<(samples.count - stripeDivisableLeftover)])
        }

        let samplesNeeded = Int(configuration.size.width) * Int(configuration.scale)
        let startSample = max(0, clampedSamples.count - samplesNeeded)
        let clippedSamples = Array(clampedSamples[startSample..<clampedSamples.count])
        let paddedSamples = clippedSamples + Array(repeating: 1, count: samplesNeeded - clippedSamples.count)

        draw(on: context, from: paddedSamples, with: configuration)
    }

    // swiftlint:enable function_parameter_count
}

// MARK: Image generation

private extension WaveformImageDrawer {
    func render(from waveformAnalyzer: WaveformAnalyzer,
                with configuration: WaveformConfiguration,
                qos: DispatchQoS.QoSClass,
                completionHandler: @escaping (_ waveformImage: UIImage?) -> ()) {
        let sampleCount = Int(configuration.size.width * configuration.scale)
        waveformAnalyzer.samples(count: sampleCount, qos: qos) { samples in
            guard let samples = samples else {
                completionHandler(nil)
                return
            }
            completionHandler(self.waveformImage(from: samples, with: configuration))
        }
    }

    private func draw(on context: CGContext, from samples: [Float], with configuration: WaveformConfiguration) {
        context.setAllowsAntialiasing(configuration.shouldAntialias)
        context.setShouldAntialias(configuration.shouldAntialias)

        drawBackground(on: context, with: configuration)
        drawGraph(from: samples, on: context, with: configuration)
    }

    private func drawBackground(on context: CGContext, with configuration: WaveformConfiguration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
    }

    private func drawGraph(from samples: [Float],
                           on context: CGContext,
                           with configuration: WaveformConfiguration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let positionAdjustedGraphCenter = CGFloat(configuration.position.value()) * graphRect.size.height
        let positionCorrectionFactor = CGFloat(0.5 + abs(configuration.position.value() - 0.5)) // middle has only half the size available
        let drawMappingFactor = graphRect.size.height * configuration.verticalScalingFactor * positionCorrectionFactor
        let minimumGraphAmplitude: CGFloat = 1 / configuration.scale // we want to see at least a 1px line for silence

        let path = CGMutablePath()
        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'

        for (x, sample) in samples.enumerated() {
            if case .striped = configuration.style, x % stripeCount(configuration) != 0 {
                continue
            }

            let xPos = CGFloat(x) / configuration.scale
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor) * configuration.scale
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
            context.setLineWidth(config.width / configuration.scale)
        } else {
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

    private func stripeCount(_ configuration: WaveformConfiguration) -> Int {
        if case let .striped(stripeConfig) = configuration.style {
            return Int(configuration.size.width / (stripeConfig.width + (stripeConfig.spacing / 2)))
        } else {
            return 0
        }
    }
}
