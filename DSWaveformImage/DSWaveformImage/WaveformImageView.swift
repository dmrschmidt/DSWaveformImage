import Foundation
import AVFoundation
import UIKit

public class WaveformImageView: UIImageView {
    private let waveformImageDrawer: WaveformImageDrawer
    private var waveformAnalyzer: WaveformAnalyzer?

    public var configuration: WaveformConfiguration {
        didSet { updateWaveform() }
    }

    public var waveformAudioURL: URL? {
        didSet { updateWaveform() }
    }

    override public init(frame: CGRect) {
        configuration = WaveformConfiguration(size: frame.size)
        waveformImageDrawer = WaveformImageDrawer()
        super.init(frame: frame)
    }

    required public init?(coder aDecoder: NSCoder) {
        configuration = WaveformConfiguration()
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
        waveformImageDrawer.waveformImage(
            fromAudioAt: audioURL,
            with: configuration.with(size: bounds.size),
            qos: .userInteractive
        ) { image in
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}
