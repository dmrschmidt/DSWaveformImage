import Foundation
import CoreGraphics

public struct LinearWaveformRenderer: WaveformRenderer {
    public init() {}

    public func render(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let positionAdjustedGraphCenter = CGFloat(configuration.position.origin().y) * graphRect.size.height
        var path = CGMutablePath()

        path.move(to: CGPoint(x: 0, y: positionAdjustedGraphCenter))

        if case .striped = configuration.style {
            path = dos(samples: samples, on: context, path: path, with: configuration, lastOffset: lastOffset, sides: .both)
        } else {
            path = dos(samples: samples, on: context, path: path, with: configuration, lastOffset: lastOffset, sides: .up)
            path = dos(samples: samples.reversed(), on: context, path: path, with: configuration, lastOffset: lastOffset, sides: .down)
        }

        path.closeSubpath()
        context.addPath(path)
    }

    public func style(context: CGContext, with configuration: Waveform.Configuration) {
        defaultStyle(context: context, with: configuration)
    }

    private func stripeBucket(_ configuration: Waveform.Configuration) -> Int {
        if case let .striped(stripeConfig) = configuration.style {
            return Int(stripeConfig.width + stripeConfig.spacing) * Int(configuration.scale)
        } else {
            return 0
        }
    }

    enum Sides {
        case up, down, both
    }

    private func dos(samples: [Float], on context: CGContext, path: CGMutablePath, with configuration: Waveform.Configuration, lastOffset: Int, sides: Sides) -> CGMutablePath {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let positionAdjustedGraphCenter = CGFloat(configuration.position.origin().y) * graphRect.size.height
        let drawMappingFactor = graphRect.size.height * configuration.verticalScalingFactor
        let minimumGraphAmplitude: CGFloat = 1 / configuration.scale // we want to see at least a 1px line for silence
        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'

        for (index, sample) in samples.enumerated() {
            let adjustedIndex: Int
            switch sides {
            case .up, .both: adjustedIndex = index
            case .down: adjustedIndex = samples.count - index
            }

            var x = adjustedIndex + lastOffset
            if case .striped = configuration.style, x % Int(configuration.scale) != 0 || x % stripeBucket(configuration) != 0 {
                // skip sub-pixels - any x value not scale aligned
                // skip any point that is not a multiple of our bucket width (width + spacing)
                continue
            } else if case let .striped(config) = configuration.style {
                // ensure 1st stripe is drawn completely inside bounds and does not clip half way on the left side
                x += Int(config.width / 2 * configuration.scale)
            }

            let samplesNeeded = Int(configuration.size.width * configuration.scale)
            let xOffset = CGFloat(samplesNeeded - samples.count) / configuration.scale // When there's extra space, draw waveform on the right
            let xPos = (CGFloat(x - lastOffset) / configuration.scale) + xOffset
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
            maxAmplitude = max(drawingAmplitude, maxAmplitude)

            switch sides {
            case .up:
                path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeUp))

            case .down:
                path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))

            case .both:
                path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
                path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
            }
        }

        return path
    }
}
