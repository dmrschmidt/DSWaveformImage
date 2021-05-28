import AVFoundation
import UIKit

/**
 Position of the drawn waveform:
 - **top**: Draws the waveform at the top of the image, such that only the bottom 50% are visible.
 - **top**: Draws the waveform in the middle the image, such that the entire waveform is visible.
 - **bottom**: Draws the waveform at the bottom of the image, such that only the top 50% are visible.
 */
public enum WaveformPosition {
    case top
    case middle
    case bottom
    case custom(Double)

    func value() -> Double {
        switch self {
        case .top: return 0.0
        case .middle: return 0.5
        case .bottom: return 1.0
        case .custom(let value): return min(1.0, max(0.0, value))
        }
    }
}

/**
 Style of the waveform which is used during drawing:
 - **filled**: Use solid color for the waveform.
 - **gradient**: Use gradient based on color for the waveform.
 - **striped**: Use striped filling based on color for the waveform.
 */
public enum WaveformStyle {
    public struct StripeConfig {
        /// Color of the waveform stripes. Default is clear.
        public let color: UIColor

        /// Width of stripes drawn. Default is `1`
        public let width: CGFloat

        /// Space between stripes. Default is `5`
        public let spacing: CGFloat

        /// Line cap style. Default is `.square`.
        public let lineCap: CGLineCap

        public init(color: UIColor, width: CGFloat = 1, spacing: CGFloat = 5, lineCap: CGLineCap = .square) {
            self.color = color
            self.width = width
            self.spacing = spacing
            self.lineCap = lineCap
        }
    }

    case filled(UIColor)
    case gradient([UIColor])
    case striped(StripeConfig)
}

/// Allows customization of the waveform output image.
public struct WaveformConfiguration {
    /// Desired output size of the waveform image, works together with scale.
    let size: CGSize

    /// Background color of the waveform, defaults to clear.
    let backgroundColor: UIColor

    /// Waveform drawing style, defaults to .gradient.
    let style: WaveformStyle

    /// Waveform drawing position, defaults to .middle.
    let position: WaveformPosition

    /// Scale to be applied to the image, defaults to main screen's scale.
    let scale: CGFloat

    /// Optional padding or vertical shrinking factor for the waveform.
    let paddingFactor: CGFloat?

    /// Waveform antialiasing. If enabled, may reduce overall opacity. Default is false.
    let shouldAntialias: Bool

    public init(size: CGSize,
                backgroundColor: UIColor = UIColor.clear,
                style: WaveformStyle = .gradient([UIColor.black, UIColor.gray]),
                position: WaveformPosition = .middle,
                scale: CGFloat = UIScreen.main.scale,
                paddingFactor: CGFloat? = nil,
                shouldAntialias: Bool = false) {
        self.backgroundColor = backgroundColor
        self.style = style
        self.position = position
        self.size = size
        self.scale = scale
        self.paddingFactor = paddingFactor
        self.shouldAntialias = shouldAntialias
    }
}
