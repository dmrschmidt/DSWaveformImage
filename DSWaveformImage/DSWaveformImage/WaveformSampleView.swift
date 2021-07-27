import Foundation

public class WaveformSampleView: UIView {
    private var sampleLayer: WaveformSampleLayer! {
        return layer as? WaveformSampleLayer
    }

    public var samples: [Float] = [] {
        didSet {
            sampleLayer.samples = samples
        }
    }

    public var waveformConfiguration = WaveformConfiguration(size: .zero) {
        didSet {
            sampleLayer.waveformConfiguration = waveformConfiguration
        }
    }

    override public class var layerClass: AnyClass {
        return WaveformSampleLayer.self
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .redraw
    }
}

class WaveformSampleLayer: CALayer {
    @NSManaged var samples: [Float]

    var waveformConfiguration = WaveformConfiguration(size: .zero) {
        didSet { contentsScale = waveformConfiguration.scale }
    }

    private let imageDrawer = WaveformImageDrawer()

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

        imageDrawer.waveformImage(from: samples, with: waveformConfiguration, context: context)

        UIGraphicsPopContext()
    }
}
