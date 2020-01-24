import Foundation
import AVFoundation
import UIKit

public class WaveformImageView: UIImageView {
    private let waveformImageDrawer: WaveformImageDrawer
    private var waveformAnalyzer: WaveformAnalyzer?

    public var waveformColor: UIColor {
        didSet { updateWaveform() }
    }

    public var waveformStyle: WaveformStyle {
        didSet { updateWaveform() }
    }

    public var waveformPosition: WaveformPosition {
        didSet { updateWaveform() }
    }

    public var waveformAudioURL: URL? {
        didSet { updateWaveform() }
    }

    override public init(frame: CGRect) {
        waveformColor = UIColor.darkGray
        waveformStyle = .gradient
        waveformPosition = .middle
        waveformImageDrawer = WaveformImageDrawer()
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        waveformColor = UIColor.darkGray
        waveformStyle = .gradient
        waveformPosition = .middle
        waveformImageDrawer = WaveformImageDrawer()
        super.init(coder: aDecoder)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateWaveform()
    }
}

private extension WaveformImageView {
    func updateWaveform() {
        guard let audioURL = waveformAudioURL else { return }
        waveformImageDrawer.waveformImage(fromAudioAt: audioURL, size: bounds.size, color: waveformColor,
                                          style: waveformStyle, position: waveformPosition,
                                          scale: UIScreen.main.scale, qos: .userInitiated) { image in
                                            DispatchQueue.main.async {
                                                self.image = image
                                            }
        }
    }
}
