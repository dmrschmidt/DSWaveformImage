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
    case filled(UIColor)
    case gradient([UIColor])
    case striped(UIColor)
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

    /// Width of stripes drawn when style is .striped. Default is 1
    let stripeWidth: CGFloat?

    /// Space between strips when style is .striped. Default is 5
    let stripeSpacing: CGFloat?

    /// Waveform antialiasing. If enabled, may reduce overall opacity. Default is false.
    let shouldAntialias: Bool

    public init(size: CGSize,
                backgroundColor: UIColor = UIColor.clear,
                style: WaveformStyle = .gradient([UIColor.black, UIColor.gray]),
                position: WaveformPosition = .middle,
                scale: CGFloat = UIScreen.main.scale,
                paddingFactor: CGFloat? = nil,
                stripeWidth: CGFloat? = nil,
                stripeSpacing: CGFloat? = nil,
                shouldAntialias: Bool = false) {
        self.backgroundColor = backgroundColor
        self.style = style
        self.position = position
        self.size = size
        self.scale = scale
        self.paddingFactor = paddingFactor
        self.stripeWidth = stripeWidth
        self.stripeSpacing = stripeSpacing
        self.shouldAntialias = shouldAntialias
    }
}
