import AVFoundation
import UIKit

public enum Waveform {
    /**
     Position of the drawn waveform:
     - **top**: Draws the waveform at the top of the image, such that only the bottom 50% are visible.
     - **top**: Draws the waveform in the middle the image, such that the entire waveform is visible.
     - **bottom**: Draws the waveform at the bottom of the image, such that only the top 50% are visible.
     */
    public enum Position: Equatable {
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
    public enum Style: Equatable {
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

    /**
     Defines the dampening attributes of the waveform.
     */
    public struct Dampening {
        public enum Sides {
            case left
            case right
            case both
        }

        /// Determines the percentage of the resulting graph to be dampened.
        ///
        /// Must be within `(0..<0.5)` to leave an undapmened area.
        /// Default is `0.125`
        public let percentage: Float

        /// Determines which sides of the graph to dampen.
        /// Default is `.both`
        public let sides: Sides

        /// Easing function to be used. Default is `pow(x, 2)`.
        public let easing: (Float) -> Float

        public init(percentage: Float = 0.125, sides: Sides = .both, easing: @escaping (Float) -> Float = { x in pow(x, 2) }) {
            guard (0...0.5).contains(percentage) else {
                preconditionFailure("dampeningPercentage must be within (0..<0.5)")
            }

            self.percentage = percentage
            self.sides = sides
            self.easing = easing
        }

        /// Build a new `Waveform.Dampening` with only the given parameters replaced.
        public func with(percentage: Float? = nil, sides: Sides? = nil, easing: ((Float) -> Float)? = nil) -> Dampening {
            .init(percentage: percentage ?? self.percentage, sides: sides ?? self.sides, easing: easing ?? self.easing)
        }
    }

    /// Allows customization of the waveform output image.
    public struct Configuration {
        /// Desired output size of the waveform image, works together with scale. Default is `.zero`.
        public let size: CGSize

        /// Background color of the waveform, defaults to `clear`.
        public let backgroundColor: UIColor

        /// Waveform drawing style, defaults to `.gradient`.
        public let style: Style

        /// *Optional* Waveform dampening, defaults to `nil`.
        public let dampening: Dampening?

        /// Waveform drawing position, defaults to `.middle`.
        public let position: Position

        /// Scale (@2x, @3x, etc.) to be applied to the image, defaults to `UIScreen.main.scale`.
        public let scale: CGFloat

        /// *Optional* padding or vertical shrinking factor for the waveform.
        @available(swift, obsoleted: 3.0, message: "Please use scalingFactor instead")
        public let paddingFactor: CGFloat? = nil

        /**
         Vertical scaling factor. Default is `0.95`, leaving a small vertical padding.

         The `verticalScalingFactor` replaced `paddingFactor` to be more approachable.
         It describes the maximum vertical amplitude of the envelope being drawn
         in relation to its view's (image's) size.

         * `0`: the waveform has no vertical amplitude and is just a line.
         * `1`: the waveform uses the full available vertical space.
         * `> 1`: louder waveform samples will extend out of the view boundaries and clip.
         */
        public let verticalScalingFactor: CGFloat

        /// Waveform antialiasing. If enabled, may reduce overall opacity. Default is `false`.
        public let shouldAntialias: Bool

        var shouldDampen: Bool {
            dampening != nil
        }

        @available(*, deprecated, message: "paddingFactor has been replaced by scalingFactor")
        public init(size: CGSize = .zero,
                    backgroundColor: UIColor = UIColor.clear,
                    style: Style = .gradient([UIColor.black, UIColor.gray]),
                    position: Position = .middle,
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
                    style: Style = .gradient([UIColor.black, UIColor.gray]),
                    dampening: Dampening? = nil,
                    position: Position = .middle,
                    scale: CGFloat = UIScreen.main.scale,
                    verticalScalingFactor: CGFloat = 0.95,
                    shouldAntialias: Bool = false) {
            guard verticalScalingFactor > 0 else {
                preconditionFailure("verticalScalingFactor must be greater 0")
            }

            self.backgroundColor = backgroundColor
            self.style = style
            self.dampening = dampening
            self.position = position
            self.size = size
            self.scale = scale
            self.verticalScalingFactor = verticalScalingFactor
            self.shouldAntialias = shouldAntialias
        }

        /// Build a new `Waveform.Configuration` with only the given parameters replaced.
        public func with(size: CGSize? = nil,
                         backgroundColor: UIColor? = nil,
                         style: Style? = nil,
                         dampening: Dampening? = nil,
                         position: Position? = nil,
                         scale: CGFloat? = nil,
                         verticalScalingFactor: CGFloat? = nil,
                         shouldAntialias: Bool? = nil
        ) -> Configuration {
            Configuration(
                size: size ?? self.size,
                backgroundColor: backgroundColor ?? self.backgroundColor,
                style: style ?? self.style,
                dampening: dampening ?? self.dampening,
                position: position ?? self.position,
                scale: scale ?? self.scale,
                verticalScalingFactor: verticalScalingFactor ?? self.verticalScalingFactor,
                shouldAntialias: shouldAntialias ?? self.shouldAntialias
            )
        }
    }

}
