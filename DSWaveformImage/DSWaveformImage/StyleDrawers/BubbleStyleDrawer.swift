import Foundation
import UIKit

struct BubbleStyleDrawer: StyleDrawer {
    func drawGraph(from samples: [Float], on context: CGContext, with configuration: WaveformConfiguration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let center = CGPoint(x: graphRect.size.width / 2, y: graphRect.size.height / 2)
//        let positionAdjustedGraphCenter = CGFloat(configuration.position.value()) * graphRect.size.height
//        let verticalPaddingDivisor = configuration.paddingFactor ?? CGFloat(configuration.position.value() == 0.5 ? 2.5 : 1.5)
//        let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
//        let minimumGraphAmplitude: CGFloat = 1 // we want to see at least a 1pt line for silence
        
//        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'
        context.setLineWidth(1.0 / configuration.scale)
        for (x, sample) in samples.enumerated() {
//            let xPos = CGFloat(x) / configuration.scale
            let invertedDbSample = 1 - CGFloat(sample) // sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
//            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
//            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
//            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
//            maxAmplitude = max(drawingAmplitude, maxAmplitude)
//
//            if configuration.style == .striped && (Int(xPos) % 5 != 0) { continue }
//
//            path.move(to: CGPoint(x: xPos, y: drawingAmplitudeUp))
//            path.addLine(to: CGPoint(x: xPos, y: drawingAmplitudeDown))
            let distance = invertedDbSample
            let circleSize = invertedDbSample * 10
            drawCircle(around: center, on: 30, of: context, rad: circleSize, distance: distance, size: invertedDbSample)
        }
//        context.addPath(path)
//        context.setStrokeColor(configuration.color.cgColor)
//        context.strokePath()
    }

    private var padding: CGFloat { return 10 }
    private var centerRadius: CGFloat { return 10 }
    private var minCircleRadius: CGFloat { return 1 }
    private var maxCircleRadius: CGFloat { return 10 }
    private var shiftDegree: CGFloat { return 10 }
    private var brightness: CGFloat { return 1 }
}

private extension BubbleStyleDrawer {
    func radius(in rect: CGRect) -> CGFloat {
        return min(rect.size.width, rect.size.height) / 2 - padding
    }

    func color(at rad: CGFloat, distance: CGFloat) -> UIColor {
        return UIColor(hue: rad / (2 * .pi), saturation: distance, brightness: brightness, alpha: 1)
    }

    func drawCircle(around center: CGPoint, on outerRadius: CGFloat,
                    of context: CGContext, rad: CGFloat, distance: CGFloat,
                    size: CGFloat) {
        let circleRadius = dotRadius(distance: size)
        let center = position(around: center, on: outerRadius, rad: rad, distance: distance)
        let circleColor = color(at: rad, distance: distance)
        let circleRect = CGRect(x: center.x - circleRadius,
                y: center.y - circleRadius,
                width: circleRadius * 2,
                height: circleRadius * 2)
        context.setLineWidth(circleRadius)
        context.setStrokeColor(circleColor.cgColor)
        context.setFillColor(circleColor.cgColor)
        context.addEllipse(in: circleRect)
        context.drawPath(using: .fillStroke)
    }

    func dotRadius(distance: CGFloat) -> CGFloat {
        guard distance > 0 else { return centerRadius }
        return max(minCircleRadius, maxCircleRadius * distance)
    }

    func position(around center: CGPoint, on radius: CGFloat, rad: CGFloat, distance: CGFloat) -> CGPoint {
        let x = center.x + (radius - padding) * distance * 10 * cos(-rad)
        let y = center.y + (radius - padding) * distance * 10 * sin(rad)
        return CGPoint(x: x, y: y)
    }
}