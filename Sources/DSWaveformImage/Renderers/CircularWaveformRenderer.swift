import Foundation
import CoreGraphics

public struct CircularWaveformRenderer: WaveformRenderer {
    public enum Kind {
        case circle
        case ring(CGFloat)
    }

    private let kind: Kind

    public init(kind: Kind = .circle) {
        self.kind = kind
    }

    public func render(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int) {
        switch kind {
        case .circle: drawCircle(samples: samples, on: context, with: configuration, lastOffset: lastOffset)
        case .ring: drawRing(samples: samples, on: context, with: configuration, lastOffset: lastOffset)
        }
    }

    public func style(context: CGContext, with configuration: Waveform.Configuration) {
        if case let .gradient(colors) = configuration.style {
            context.clip()
            let colors = NSArray(array: colors.map { (color: DSColor) -> CGColor in color.cgColor }) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: 0),
                                       end: CGPoint(x: 0, y: configuration.size.height),
                                       options: .drawsAfterEndLocation)
        } else {
            defaultStyle(context: context, with: configuration)
        }
    }

    private func drawCircle(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int) {
        let graphRect = CGRect(origin: .zero, size: configuration.size)
        let maxRadius = CGFloat(min(graphRect.maxX, graphRect.maxY) / 2.0) * configuration.verticalScalingFactor
        let center = CGPoint(x: graphRect.maxX * 0.5, y: graphRect.maxY * 0.5)
        let path = CGMutablePath()

        path.move(to: center)

        for (index, sample) in samples.enumerated() {
            let angle = CGFloat.pi * 2 * (CGFloat(index) / CGFloat(samples.count))
            let x = index + lastOffset

            if case .striped = configuration.style, x % Int(configuration.scale) != 0 || x % stripeBucket(configuration) != 0 {
                // skip sub-pixels - any x value not scale aligned
                // skip any point that is not a multiple of our bucket width (width + spacing)
                path.addLine(to: center)
                continue
            }

            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let pointOnCircle = CGPoint(
                x: center.x + maxRadius * invertedDbSample * cos(angle),
                y: center.y + maxRadius * invertedDbSample * sin(angle)
            )

            path.addLine(to: pointOnCircle)
        }

        path.closeSubpath()
        context.addPath(path)
    }

    private func drawRing(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int) {
        guard case let .ring(config) = kind else {
            return
        }

        let graphRect = CGRect(origin: .zero, size: configuration.size)
        let maxRadius = CGFloat(min(graphRect.maxX, graphRect.maxY) / 2.0) * configuration.verticalScalingFactor
        let innerRadius: CGFloat = maxRadius * config
        let center = CGPoint(x: graphRect.maxX * 0.5, y: graphRect.maxY * 0.5)
        let path = CGMutablePath()

        path.move(to: CGPoint(
            x: center.x + innerRadius * cos(0),
            y: center.y + innerRadius * sin(0)
        ))

        for (index, sample) in samples.enumerated() {
            let x = index + lastOffset
            let angle = CGFloat.pi * 2 * (CGFloat(index) / CGFloat(samples.count))

            if case .striped = configuration.style, x % Int(configuration.scale) != 0 || x % stripeBucket(configuration) != 0 {
                // skip sub-pixels - any x value not scale aligned
                // skip any point that is not a multiple of our bucket width (width + spacing)
                path.move(to: CGPoint(
                    x: center.x + innerRadius * cos(angle),
                    y: center.y + innerRadius * sin(angle)
                ))
                continue
            }

            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let pointOnCircle = CGPoint(
                x: center.x + innerRadius * cos(angle) + (maxRadius - innerRadius) * invertedDbSample * cos(angle),
                y: center.y + innerRadius * sin(angle) + (maxRadius - innerRadius) * invertedDbSample * sin(angle)
            )

            path.addLine(to: pointOnCircle)
        }

        path.closeSubpath()
        context.addPath(path)
    }

    private func stripeBucket(_ configuration: Waveform.Configuration) -> Int {
        if case let .striped(stripeConfig) = configuration.style {
            return Int(stripeConfig.width + stripeConfig.spacing) * Int(configuration.scale)
        } else {
            return 0
        }
    }
}
