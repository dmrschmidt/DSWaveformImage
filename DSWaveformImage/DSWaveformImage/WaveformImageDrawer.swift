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
        let scaledSize = CGSize(width: configuration.size.width * configuration.scale,
                                height: configuration.size.height * configuration.scale)
        let scaledConfiguration = WaveformConfiguration(size: scaledSize,
                                                        backgroundColor: configuration.backgroundColor,
                                                        style: configuration.style,
                                                        position: configuration.position,
                                                        scale: configuration.scale,
                                                        paddingFactor: configuration.paddingFactor)
        guard let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioAssetURL) else {
            completionHandler(nil)
            return
        }
        render(from: waveformAnalyzer, with: scaledConfiguration, qos: qos, completionHandler: completionHandler)
    }

    /// Renders a UIImage of the waveform data calculated by the analyzer.
    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              size: CGSize,
                              backgroundColor: UIColor = UIColor.clear,
                              style: WaveformStyle = .gradient([UIColor.black, UIColor.darkGray]),
                              position: WaveformPosition = .middle,
                              scale: CGFloat = UIScreen.main.scale,
                              paddingFactor: CGFloat? = nil,
                              qos: DispatchQoS.QoSClass = .userInitiated,
                              shouldAntialias: Bool = false,
                              completionHandler: @escaping (_ waveformImage: UIImage?) -> ()) {
        let configuration = WaveformConfiguration(size: size, backgroundColor: backgroundColor,
                                                  style: style, position: position, scale: scale,
                                                  paddingFactor: paddingFactor, shouldAntialias: shouldAntialias)
        waveformImage(fromAudioAt: audioAssetURL, with: configuration, completionHandler: completionHandler)
    }

    public func waveformImage(from samples: [Float], with configuration: WaveformConfiguration) -> UIImage? {
        guard samples.count > 0 else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        let size = CGSize(width: max(configuration.size.width, CGFloat(samples.count) / configuration.scale), height: configuration.size.height)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

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
        let verticalPaddingDivisor = configuration.paddingFactor ?? CGFloat(configuration.position.value() == 0.5 ? 2.5 : 1.5)
        let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
        let minimumGraphAmplitude: CGFloat = 1 / configuration.scale / 2 // we want to see at least a 1px line for silence

        let path = CGMutablePath()
        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'

        for (x, sample) in samples.enumerated() {
            if case .striped = configuration.style, x % stripeCount(configuration) != 0 {
                continue
            }

            let xPos = CGFloat(x) / configuration.scale
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
            context.setLineWidth(config.width)
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
            return Int(configuration.size.width / (stripeConfig.width + stripeConfig.spacing))
        } else {
            return 0
        }
    }
}
