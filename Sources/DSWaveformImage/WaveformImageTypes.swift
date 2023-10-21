import AVFoundation

#if os(macOS)
    import AppKit

    public typealias DSColor = NSColor
    public typealias DSImage = NSImage
    public enum DSScreen {
        public static var scale: CGFloat { NSScreen.main?.backingScaleFactor ?? 1 }
    }
#else
    import UIKit

    public typealias DSColor = UIColor
    public typealias DSImage = UIImage
    public enum DSScreen {
        public static var scale: CGFloat {
            #if swift(>=5.9) && os(visionOS)
            return (UIApplication.shared.connectedScenes.first(where: {$0 is UIWindowScene}) as? UIWindowScene)?.traitCollection.displayScale ?? 1
            #else
            return UIScreen.main.scale
            #endif
        }
    }
#endif

/**
 Renders the waveformsamples  on the provided `CGContext`.

 Default implementations are `LinearWaveformRenderer` and `CircularWaveformRenderer`.
 Check out those if you'd like to implement your own custom renderer.
*/
public protocol WaveformRenderer: Sendable {

    /**
     Calculates a CGPath from the waveform samples.

     - Parameters:
        - samples: `[Float]` of the amplitude envelope to be drawn, normalized to interval `(0...1)`. `0` is maximum (typically `0dB`).
        `1` is the noise floor, typically `-50dB`, as defined in `WaveformAnalyzer.noiseFloorDecibelCutoff`.
        - lastOffset: You can typtically leave this `0`. **Required for live rendering**, where it is needed to keep track of the last drawing cycle. Setting it avoids 'flickering' as samples are being added
         continuously and the waveform moves across the view.
     */
    func path(samples: [Float], with configuration: Waveform.Configuration, lastOffset: Int) -> CGPath

    /**
     Renders the waveform samples  on the provided `CGContext`.

     - Parameters:
        - samples: `[Float]` of the amplitude envelope to be drawn, normalized to interval `(0...1)`. `0` is maximum (typically `0dB`).
        `1` is the noise floor, typically `-50dB`, as defined in `WaveformAnalyzer.noiseFloorDecibelCutoff`.
        - with configuration: The desired configuration to be used for drawing.
        - lastOffset: You can typtically leave this `0`. **Required for live rendering**, where it is needed to keep track of the last drawing cycle. Setting it avoids 'flickering' as samples are being added
         continuously and the waveform moves across the view.
     */
    func render(samples: [Float], on context: CGContext, with configuration: Waveform.Configuration, lastOffset: Int)
}

public enum Waveform {
    /**
     Style of the waveform which is used during drawing:
     - **filled**: Use solid color for the waveform.
     - **outlined**: Draws the envelope as an outline with the provided thickness.
     - **gradient**: Use gradient based on color for the waveform.
     - **gradientOutlined**: Use gradient based on color for the waveform. Draws the envelope as an outline with the provided thickness.
     - **striped**: Use striped filling based on color for the waveform.
     */
    public enum Style: Equatable, Sendable {
        public struct StripeConfig: Equatable, Sendable {
            /// Color of the waveform stripes. Default is clear.
            public let color: DSColor

            /// Width of stripes drawn. Default is `1`
            public let width: CGFloat

            /// Space between stripes. Default is `5`
            public let spacing: CGFloat

            /// Line cap style. Default is `.round`.
            public let lineCap: CGLineCap

            public init(color: DSColor, width: CGFloat = 1, spacing: CGFloat = 5, lineCap: CGLineCap = .round) {
                self.color = color
                self.width = width
                self.spacing = spacing
                self.lineCap = lineCap
            }
        }

        case filled(DSColor)
        case outlined(DSColor, CGFloat)
        case gradient([DSColor])
        case gradientOutlined([DSColor], CGFloat)
        case striped(StripeConfig)
    }

    /**
     Defines the damping attributes of the waveform.
     */
    public struct Damping: Equatable, Sendable {
        public enum Sides: Equatable, Sendable {
            case left
            case right
            case both
        }

        /// Determines the percentage of the resulting graph to be damped.
        ///
        /// Must be within `(0..<0.5)` to leave an undapmened area.
        /// Default is `0.125`
        public let percentage: Float

        /// Determines which sides of the graph to damp.
        /// Default is `.both`
        public let sides: Sides

        /// Easing function to be used. Default is `pow(x, 2)`.
        public let easing: @Sendable (Float) -> Float

        public init(percentage: Float = 0.125, sides: Sides = .both, easing: @escaping @Sendable (Float) -> Float = { x in pow(x, 2) }) {
            guard (0...0.5).contains(percentage) else {
                preconditionFailure("dampingPercentage must be within (0..<0.5)")
            }

            self.percentage = percentage
            self.sides = sides
            self.easing = easing
        }

        /// Build a new `Waveform.Damping` with only the given parameters replaced.
        public func with(percentage: Float? = nil, sides: Sides? = nil, easing: (@Sendable (Float) -> Float)? = nil) -> Damping {
            .init(percentage: percentage ?? self.percentage, sides: sides ?? self.sides, easing: easing ?? self.easing)
        }

        public static func == (lhs: Waveform.Damping, rhs: Waveform.Damping) -> Bool {
            // poor-man's way to make two closures Equatable w/o too much hassle
            let randomEqualitySample = Float.random(in: (0..<Float.greatestFiniteMagnitude))
            return lhs.percentage == rhs.percentage && lhs.sides == rhs.sides && lhs.easing(randomEqualitySample) == rhs.easing(randomEqualitySample)
        }
    }

    /// Allows customization of the waveform output image.
    public struct Configuration: Equatable, Sendable {
        /// Desired output size of the waveform image, works together with scale. Default is `.zero`.
        public let size: CGSize

        /// Background color of the waveform, defaults to `clear`.
        public let backgroundColor: DSColor

        /// Waveform drawing style, defaults to `.gradient`.
        public let style: Style

        /// *Optional* Waveform damping, defaults to `nil`.
        public let damping: Damping?

        /// Scale (@2x, @3x, etc.) to be applied to the image, defaults to `UIScreen.main.scale`.
        public let scale: CGFloat

        /**
         Vertical scaling factor. Default is `0.95`, leaving a small vertical padding.

         The `verticalScalingFactor` describes the maximum vertical amplitude
         of the envelope being drawn in relation to its view's (image's) size.

         * `0`: the waveform has no vertical amplitude and is just a line.
         * `1`: the waveform uses the full available vertical space.
         * `> 1`: louder waveform samples will extend out of the view boundaries and clip.
         */
        public let verticalScalingFactor: CGFloat

        /// Waveform antialiasing. If enabled, may reduce overall opacity. Default is `false`.
        public let shouldAntialias: Bool

        public var shouldDamp: Bool {
            damping != nil
        }

        public init(size: CGSize = .zero,
                    backgroundColor: DSColor = DSColor.clear,
                    style: Style = .gradient([DSColor.black, DSColor.gray]),
                    damping: Damping? = nil,
                    scale: CGFloat = DSScreen.scale,
                    verticalScalingFactor: CGFloat = 0.95,
                    shouldAntialias: Bool = false) {
            guard verticalScalingFactor > 0 else {
                preconditionFailure("verticalScalingFactor must be greater 0")
            }

            self.backgroundColor = backgroundColor
            self.style = style
            self.damping = damping
            self.size = size
            self.scale = scale
            self.verticalScalingFactor = verticalScalingFactor
            self.shouldAntialias = shouldAntialias
        }

        /// Build a new `Waveform.Configuration` with only the given parameters replaced.
        public func with(size: CGSize? = nil,
                         backgroundColor: DSColor? = nil,
                         style: Style? = nil,
                         damping: Damping? = nil,
                         scale: CGFloat? = nil,
                         verticalScalingFactor: CGFloat? = nil,
                         shouldAntialias: Bool? = nil
        ) -> Configuration {
            Configuration(
                size: size ?? self.size,
                backgroundColor: backgroundColor ?? self.backgroundColor,
                style: style ?? self.style,
                damping: damping ?? self.damping,
                scale: scale ?? self.scale,
                verticalScalingFactor: verticalScalingFactor ?? self.verticalScalingFactor,
                shouldAntialias: shouldAntialias ?? self.shouldAntialias
            )
        }
    }
}
