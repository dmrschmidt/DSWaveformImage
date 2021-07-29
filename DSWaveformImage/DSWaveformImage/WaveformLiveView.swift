import Foundation
import UIKit

/// Renders a live waveform everytime its `(0...1)`-normalized samples are changed.
public class WaveformLiveView: UIView {

    /// Default configuration with dampening enabled.
    public static let defaultConfiguration = WaveformConfiguration(shouldDampenSides: true)

    public var samples: [Float] = [] {
        didSet {
            sampleLayer.samples = samples
        }
    }

    public var configuration: WaveformConfiguration {
        didSet {
            sampleLayer.configuration = configuration
        }
    }

    private var sampleLayer: WaveformLiveLayer! {
        return layer as? WaveformLiveLayer
    }

    override public class var layerClass: AnyClass {
        return WaveformLiveLayer.self
    }

    public init(configuration: WaveformConfiguration = defaultConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
        self.contentMode = .redraw
    }

    public override init(frame: CGRect) {
        self.configuration = Self.defaultConfiguration
        super.init(frame: frame)
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        self.configuration = Self.defaultConfiguration
        super.init(coder: coder)
        contentMode = .redraw
    }

    /// Clears the samples, emptying the waveform view.
    public func reset() {
        samples = []
    }
}

class WaveformLiveLayer: CALayer {
    @NSManaged var samples: [Float]

    var configuration = WaveformLiveView.defaultConfiguration {
        didSet { contentsScale = configuration.scale }
    }

    private let waveformDrawer = WaveformImageDrawer()

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(samples) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in context: CGContext) {
        super.draw(in: context)

        guard samples.count > 0 else {
            return
        }

        UIGraphicsPushContext(context)
        waveformDrawer.draw(waveform: samples, on: context, with: configuration.with(size: bounds.size))
        UIGraphicsPopContext()
    }
}
