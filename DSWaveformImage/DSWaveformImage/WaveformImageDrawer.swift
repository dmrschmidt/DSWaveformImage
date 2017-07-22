import Foundation
import AVFoundation

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif


open class WaveformImageDrawer {
    public init() {}

    // swiftlint:disable function_parameter_count
    public func waveformImage(from waveform: Waveform, with configuration: WaveformConfiguration) -> Image? {
        let scaledSize = CGSize(width: configuration.size.width * configuration.scale,
                                height: configuration.size.height * configuration.scale)
        let scaledConfiguration = WaveformConfiguration(size: scaledSize,
                                                        color: configuration.color,
                                                        backgroundColor: configuration.backgroundColor,
                                                        style: configuration.style,
                                                        position: configuration.position,
                                                        scale: configuration.scale,
                                                        paddingFactor: configuration.paddingFactor)
        return self.render(waveform: waveform, with: scaledConfiguration)
    }

    public func waveformImage(fromAudio audioAsset: AVURLAsset,
                              size: CGSize,
                              color: Color = Color.black,
                              backgroundColor: Color = Color.clear,
                              style: WaveformStyle = .gradient,
                              position: WaveformPosition = .middle,
                              scale: CGFloat = mainScreenScale,
                              paddingFactor: CGFloat? = nil) -> Image? {
        guard let waveform = Waveform(audioAsset: audioAsset) else { return nil }
        let configuration = WaveformConfiguration(size: size, color: color, backgroundColor: backgroundColor, style: style,
                                                  position: position, scale: scale, paddingFactor: paddingFactor)
        return waveformImage(from: waveform, with: configuration)
    }

    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              size: CGSize,
                              color: Color = Color.black,
                              backgroundColor: Color = Color.clear,
                              style: WaveformStyle = .gradient,
                              position: WaveformPosition = .middle,
                              scale: CGFloat = mainScreenScale,
                              paddingFactor: CGFloat? = nil) -> Image? {
        let audioAsset = AVURLAsset(url: audioAssetURL)
        return waveformImage(fromAudio: audioAsset, size: size, color: color, backgroundColor: backgroundColor, style: style,
                             position: position, scale: scale, paddingFactor: paddingFactor)
    }
    // swiftlint:enable function_parameter_count
}

// MARK: Image generation

fileprivate extension WaveformImageDrawer {
    fileprivate func render(waveform: Waveform, with configuration: WaveformConfiguration) -> Image? {
        let sampleCount = Int(configuration.size.width * configuration.scale)
        guard let imageSamples = waveform.samples(count: sampleCount) else { return nil }
        return graphImage(from: imageSamples, with: configuration)
    }

    private func graphImage(from samples: [Float], with configuration: WaveformConfiguration) -> Image? {
        #if os(OSX)
            if let context = NSGraphicsContext.current(){
                // Let's use an Image
                let image = NSImage(size: configuration.size)
                image.lockFocus()
                context.shouldAntialias = true
                drawBackground(on: context.cgContext, with: configuration)
                drawGraph(from: samples, on: context.cgContext, with: configuration)
                return image
            }else{
                // Let's draw Off screen
                NSGraphicsContext.saveGraphicsState()
                let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                           pixelsWide: Int(configuration.size.width),
                                           pixelsHigh: Int(configuration.size.height),
                                           bitsPerSample: 8,
                                           samplesPerPixel: 4,
                                           hasAlpha: true,
                                           isPlanar: false,
                                           colorSpaceName: NSCalibratedRGBColorSpace,
                                           bytesPerRow: 4  * Int(configuration.size.width),
                                           bitsPerPixel: 32)!
                NSGraphicsContext.setCurrent(NSGraphicsContext(bitmapImageRep: rep))
                let context = NSGraphicsContext.current()!
                context.shouldAntialias = true
                drawBackground(on: context.cgContext, with: configuration)
                drawGraph(from: samples, on: context.cgContext, with: configuration)
                let image = NSImage(size: configuration.size)
                image.addRepresentation(rep)
                NSGraphicsContext.restoreGraphicsState()
                return image
            }
        #elseif os(iOS)

            UIGraphicsBeginImageContextWithOptions(configuration.size, false, configuration.scale)
            let context = UIGraphicsGetCurrentContext()!
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)

            drawBackground(on: context, with: configuration)
            drawGraph(from: samples, on: context, with: configuration)

            let graphImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return graphImage
        #endif
    }

    private func drawBackground(on context: CGContext, with configuration: WaveformConfiguration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
    }

    private func drawGraph(from samples: [Float],
                           on context: CGContext,
                           with configuration: WaveformConfiguration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let graphCenter = graphRect.size.height / 2.0
        let positionAdjustedGraphCenter = graphCenter + CGFloat(configuration.position.rawValue) * graphCenter
        let verticalPaddingDivisor = configuration.paddingFactor ?? CGFloat(configuration.position == .middle ? 2.5 : 1.5)
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
