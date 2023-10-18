import Foundation
import DSWaveformImage
import SwiftUI

struct DefaultShapeStyler {
    @ViewBuilder
    func style(shape: WaveformShape, with configuration: Waveform.Configuration) -> some View {
        switch configuration.style {
        case let .filled(color):
            shape.fill(Color(color))

        case let .outlined(color, lineWidth):
            shape.stroke(
                Color(color),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )

        case let .gradient(colors):
            shape
                .fill(LinearGradient(colors: colors.map(Color.init), startPoint: .bottom, endPoint: .top))

        case let .gradientOutlined(colors, lineWidth):
            shape.stroke(
                LinearGradient(colors: colors.map(Color.init), startPoint: .bottom, endPoint: .top),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )

        case let .striped(config):
            shape.stroke(
                Color(config.color),
                style: StrokeStyle(
                    lineWidth: config.width,
                    lineCap: config.lineCap
                )
            )
        }
    }
}
