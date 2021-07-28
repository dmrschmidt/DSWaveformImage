import Foundation
import AVFoundation
import UIKit

public class WaveformImageView: UIImageView {
    private let waveformImageDrawer: WaveformImageDrawer
    private var waveformAnalyzer: WaveformAnalyzer?

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
        waveformStyle = .gradient([UIColor.black, UIColor.darkGray])
        waveformPosition = .middle
        waveformImageDrawer = WaveformImageDrawer()
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        waveformStyle = .gradient([UIColor.black, UIColor.darkGray])
        waveformPosition = .middle
        waveformImageDrawer = WaveformImageDrawer()
        super.init(coder: aDecoder)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateWaveform()
    }

    /// Clears the audio data, emptying the waveform view.
    public func reset() {
        waveformAudioURL = nil
        image = nil
    }
}

private extension WaveformImageView {
    func updateWaveform() {
        guard let audioURL = waveformAudioURL else { return }
        waveformImageDrawer.waveformImage(fromAudioAt: audioURL, size: bounds.size,
                                          style: waveformStyle, position: waveformPosition,
                                          scale: UIScreen.main.scale, qos: .userInitiated) { image in
                                            DispatchQueue.main.async {
                                                self.image = image
                                            }
        }
    }
}
