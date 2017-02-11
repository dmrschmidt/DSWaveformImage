import Foundation
import AVFoundation

public struct WaveformImageDrawer {
    public init() {}

    // swiftlint:disable function_parameter_count
    public func waveformImage(from waveform: Waveform, with configuration: WaveformConfiguration) -> UIImage? {
        let scaledSize = CGSize(width: configuration.size.width * configuration.scale,
                                height: configuration.size.height * configuration.scale)
        let scaledConfiguration = WaveformConfiguration(color: configuration.color, style: configuration.style,
                                                        position: configuration.position, size: scaledSize,
                                                        scale: configuration.scale)
        return render(waveform: waveform, with: scaledConfiguration)
    }

    public func waveformImage(fromAudio audioAsset: AVURLAsset,
                              color: UIColor,
                              style: WaveformStyle,
                              position: WaveformPosition,
                              size: CGSize,
                              scale: CGFloat) -> UIImage? {
        guard let waveform = Waveform(audioAsset: audioAsset) else { return nil }
        let configuration = WaveformConfiguration(color: color, style: style, position: position, size: size, scale: scale)
        return waveformImage(from: waveform, with: configuration)
    }

    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              color: UIColor,
                              style: WaveformStyle,
                              position: WaveformPosition,
                              size: CGSize,
                              scale: CGFloat) -> UIImage? {
        let audioAsset = AVURLAsset(url: audioAssetURL)
        return waveformImage(fromAudio: audioAsset, color: color, style: style, position: position, size: size, scale: scale)
    }
    // swiftlint:enable function_parameter_count
}

// MARK: Image generation

fileprivate extension WaveformImageDrawer {
    fileprivate func render(waveform: Waveform, with configuration: WaveformConfiguration) -> UIImage? {
        let sampleCount = Int(configuration.size.width * configuration.scale)
        guard let imageSamples = waveform.samples(count: sampleCount) else { return nil }
        return graphImage(from: imageSamples, with: configuration)
    }

    private func graphImage(from samples: [Float], with configuration: WaveformConfiguration) -> UIImage? {
        UIGraphicsBeginImageContext(configuration.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)

        drawGraph(from: samples, on: context, with: configuration)

        let graphImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return graphImage
    }

    private func drawGraph(from samples: [Float],
                           on context: CGContext,
                           with configuration: WaveformConfiguration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let graphCenter = graphRect.size.height / 2.0
        let positionAdjustedGraphCenter = graphCenter + CGFloat(configuration.position.rawValue) * graphCenter
        let verticalPaddingDivisor = CGFloat(configuration.position == .middle ? 2.5 : 1.5) // 2 = 50 % of height
        let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
        let minimumGraphAmplitude: CGFloat = 1 // we want to see at least a 1pt line for silence

        let path = CGMutablePath()
        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'
        context.setLineWidth(1.0 / configuration.scale)
        for (x, sample) in samples.enumerated() {
            let xPos = CGFloat(x) / configuration.scale
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
            maxAmplitude = max(drawingAmplitude, maxAmplitude)

            if configuration.style == .striped && (Int(xPos) % 5 != 0) { continue }

            path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
            path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
        }
        context.addPath(path)

        switch configuration.style {
        case .filled, .striped:
            context.setStrokeColor(configuration.color.cgColor)
            context.strokePath()
        case .gradient:
            context.replacePathWithStrokedPath()
            context.clip()
            let colors = NSArray(array: [
                configuration.color.cgColor,
                configuration.color.highlighted(brightnessAdjustment: 0.5).cgColor
            ]) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: positionAdjustedGraphCenter - maxAmplitude),
                                       end: CGPoint(x: 0, y: positionAdjustedGraphCenter + maxAmplitude),
                                       options: .drawsAfterEndLocation)
        }
    }
}
