import AVFoundation
import UIKit

/**
 Position of the drawn waveform:
 - **top**: Draws the waveform at the top of the image, such that only the bottom 50% are visible.
 - **top**: Draws the waveform in the middle the image, such that the entire waveform is visible.
 - **bottom**: Draws the waveform at the bottom of the image, such that only the top 50% are visible.
 */
public enum WaveformPosition: Equatable {
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
public enum WaveformStyle: Equatable {
    public struct StripeConfig: Equatable {
        /// Color of the waveform stripes. Default is clear.
        public let color: UIColor

        /// Width of stripes drawn. Default is `1`
        public let width: CGFloat

        /// Space between stripes. Default is `5`
        public let spacing: CGFloat

        /// Line cap style. Default is `.round`.
        public let lineCap: CGLineCap

        public init(color: UIColor, width: CGFloat = 1, spacing: CGFloat = 5, lineCap: CGLineCap = .round) {
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
    /// Desired output size of the waveform image, works together with scale. Default is `.zero`.
    public let size: CGSize

    /// Background color of the waveform, defaults to `clear`.
    public let backgroundColor: UIColor

    /// Waveform drawing style, defaults to `.gradient`.
    public let style: WaveformStyle

    /// Waveform drawing position, defaults to `.middle`.
    public let position: WaveformPosition

    /// Scale (@2x, @3x, etc.) to be applied to the image, defaults to `UIScreen.main.scale`.
    public let scale: CGFloat

    /// *Optional* padding or vertical shrinking factor for the waveform.
    @available(swift, obsoleted: 3.0, message: "Please use scalingFactor instead")
    public let paddingFactor: CGFloat? = nil

    /**
     Vertical scaling factor in range `(0...1)`. Default is `0.95`, leaving a small vertical padding.

     The `verticalScalingFactor` replaced `paddingFactor` to be more approachable.
     It describes the maximum vertical amplitude of the envelope being drawn
     in relation to its view's (image's) size.

     * `0`: the waveform has no vertical amplitude and is just a line.
     * `1`: the waveform uses the full available vertical space.
     */
    public let verticalScalingFactor: CGFloat

    /// If true, both graph sides (1/5th each) are linearly dampened. Default is `false`.
    public let shouldDampenSides: Bool

    /// Waveform antialiasing. If enabled, may reduce overall opacity. Default is `false`.
    public let shouldAntialias: Bool

    @available(*, deprecated, message: "paddingFactor has been replaced by scalingFactor")
    public init(size: CGSize = .zero,
                backgroundColor: UIColor = UIColor.clear,
                style: WaveformStyle = .gradient([UIColor.black, UIColor.gray]),
                position: WaveformPosition = .middle,
                scale: CGFloat = UIScreen.main.scale,
                paddingFactor: CGFloat?,
                shouldAntialias: Bool = false) {
        self.init(
            size: size, backgroundColor: backgroundColor, style: style, position: position, scale: scale,
            verticalScalingFactor: 1 / (paddingFactor ?? 1), shouldAntialias: shouldAntialias
        )
    }

    public init(size: CGSize = .zero,
                backgroundColor: UIColor = UIColor.clear,
                style: WaveformStyle = .gradient([UIColor.black, UIColor.gray]),
                position: WaveformPosition = .middle,
                scale: CGFloat = UIScreen.main.scale,
                verticalScalingFactor: CGFloat = 0.95,
                shouldDampenSides: Bool = false,
                shouldAntialias: Bool = false) {
        guard (0...1).contains(Float(verticalScalingFactor)) else {
            preconditionFailure("scalingFactor must be within [0...1]")
        }

        self.backgroundColor = backgroundColor
        self.style = style
        self.position = position
        self.size = size
        self.scale = scale
        self.verticalScalingFactor = verticalScalingFactor
        self.shouldDampenSides = shouldDampenSides
        self.shouldAntialias = shouldAntialias
    }

    /// Build a new `WaveformConfiguration` with only the given parameters replaced.
    public func with(size: CGSize? = nil,
                     backgroundColor: UIColor? = nil,
                     style: WaveformStyle? = nil,
                     position: WaveformPosition? = nil,
                     scale: CGFloat? = nil,
                     verticalScalingFactor: CGFloat? = nil,
                     shouldAntialias: Bool? = nil
    ) -> WaveformConfiguration {
        WaveformConfiguration(
            size: size ?? self.size,
            backgroundColor: backgroundColor ?? self.backgroundColor,
            style: style ?? self.style,
            position: position ?? self.position,
            scale: scale ?? self.scale,
            verticalScalingFactor: verticalScalingFactor ?? self.verticalScalingFactor,
            shouldAntialias: shouldAntialias ?? self.shouldAntialias
        )
    }
}
