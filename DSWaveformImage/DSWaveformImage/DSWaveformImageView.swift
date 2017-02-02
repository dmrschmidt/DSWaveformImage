import Foundation
import AVFoundation
import UIKit

public class DSWaveformImageView: UIImageView {
    fileprivate let waveformImageDrawer: DSWaveformImageDrawer

    public var waveformColor: UIColor {
        didSet { updateWaveform() }
    }

    public var waveformStyle: DSWaveformStyle {
        didSet { updateWaveform() }
    }

    public var waveformPosition: DSWaveformPosition {
        didSet { updateWaveform() }
    }

    public var waveformAudioURL: URL? {
        didSet { updateWaveform() }
    }

    override public init(frame: CGRect) {
        waveformColor = UIColor.darkGray
        waveformStyle = .gradient
        waveformPosition = .middle
        waveformImageDrawer = DSWaveformImageDrawer()
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        waveformColor = UIColor.darkGray
        waveformStyle = .gradient
        waveformPosition = .middle
        waveformImageDrawer = DSWaveformImageDrawer()
        super.init(coder: aDecoder)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateWaveform()
    }
}

fileprivate extension DSWaveformImageView {
    func updateWaveform() {
        guard let audioURL = waveformAudioURL else { return }
        image = waveformImageDrawer.waveformImage(fromAudioAt: audioURL, color: waveformColor, style: waveformStyle,
                                                  position: waveformPosition, size: bounds.size,
                                                  scale: UIScreen.main.scale)
    }
}
