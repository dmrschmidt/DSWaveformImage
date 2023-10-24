#if os(iOS) || swift(>=5.9) && os(visionOS)
import DSWaveformImage
import Foundation
import UIKit

/// Renders a live waveform everytime its `(0...1)`-normalized samples are changed.
public class WaveformLiveView: UIView {

    /// Default configuration with damping enabled.
    public static let defaultConfiguration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both))

    /// If set to `true`, a zero line, indicating silence, is being drawn while the received
    /// samples are not filling up the entire view's width yet.
    public var shouldDrawSilencePadding: Bool = false {
        didSet {
            sampleLayer.shouldDrawSilencePadding = shouldDrawSilencePadding
        }
    }

    public var configuration: Waveform.Configuration {
        didSet {
            sampleLayer.configuration = configuration
        }
    }

    /// Returns the currently used samples.
    public var samples: [Float] {
        sampleLayer.samples
    }

    private var sampleLayer: WaveformLiveLayer! {
        return layer as? WaveformLiveLayer
    }

    override public class var layerClass: AnyClass {
        return WaveformLiveLayer.self
    }

    public var renderer: WaveformRenderer {
        didSet {
            sampleLayer.renderer = renderer
        }
    }

    public init(configuration: Waveform.Configuration = defaultConfiguration, renderer: WaveformRenderer = LinearWaveformRenderer()) {
        self.configuration = configuration
        self.renderer = renderer
        super.init(frame: .zero)
        self.contentMode = .redraw

        defer { // will call didSet to propagate to sampleLayer
            self.configuration = configuration
            self.renderer = renderer
        }
    }

    public override init(frame: CGRect) {
        self.configuration = Self.defaultConfiguration
        self.renderer = LinearWaveformRenderer()
        super.init(frame: frame)
        contentMode = .redraw

        defer { // will call didSet to propagate to sampleLayer
            self.configuration = Self.defaultConfiguration
            self.renderer = LinearWaveformRenderer()
        }
    }

    required init?(coder: NSCoder) {
        self.configuration = Self.defaultConfiguration
        self.renderer = LinearWaveformRenderer()
        super.init(coder: coder)
        contentMode = .redraw

        defer { // will call didSet to propagate to sampleLayer
            self.configuration = Self.defaultConfiguration
            self.renderer = LinearWaveformRenderer()
        }
    }

    /// The sample to be added. Re-draws the waveform with the pre-existing samples and the new one.
    /// Value must be within `(0...1)` to make sense (0 being loweset and 1 being maximum amplitude).
    public func add(sample: Float) {
        sampleLayer.add([sample])
    }

    /// The samples to be added. Re-draws the waveform with the pre-existing samples and the new ones.
    /// Values must be within `(0...1)` to make sense (0 being loweset and 1 being maximum amplitude).
    public func add(samples: [Float]) {
        sampleLayer.add(samples)
    }

    /// Clears the samples, emptying the waveform view.
    public func reset() {
        sampleLayer.reset()
    }
}

class WaveformLiveLayer: CALayer {
    @NSManaged var samples: [Float]

    var configuration = WaveformLiveView.defaultConfiguration {
        didSet { contentsScale = configuration.scale }
    }

    var shouldDrawSilencePadding: Bool = false {
        didSet {
            waveformDrawer.shouldDrawSilencePadding = shouldDrawSilencePadding
            setNeedsDisplay()
        }
    }

    var renderer: WaveformRenderer = LinearWaveformRenderer() {
        didSet { setNeedsDisplay() }
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

        UIGraphicsPushContext(context)
        waveformDrawer.draw(waveform: samples, on: context, with: configuration.with(size: bounds.size), renderer: renderer)
        UIGraphicsPopContext()
    }

    func add(_ newSamples: [Float]) {
        samples += newSamples
    }

    func reset() {
        samples = []
    }
}
#endif
