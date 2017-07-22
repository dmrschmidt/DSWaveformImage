import Foundation
import AVFoundation

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif


@objc open class WaveformImageView: ImageView {

    lazy var waveformImageDrawer: WaveformImageDrawer =  WaveformImageDrawer()

    public var waveformColor: Color = Color.darkGray{
        didSet { self._needsDisplay() }
    }

    public var waveformStyle: WaveformStyle = .gradient {
        didSet { self._needsDisplay() }
    }

    public var waveformPosition: WaveformPosition = .middle{
        didSet { self._needsDisplay()}
    }

    public var waveformAudioURL: URL? {
        didSet { self._needsDisplay() }
    }
    

    fileprivate func _needsDisplay(){
        #if os(OSX)
            self.needsDisplay = true
        #elseif os(iOS)
            self.setNeedsDisplay()
        #endif
    }


    #if os(OSX)

    open override func draw(_ rect: CGRect) {
       updateWaveform()
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    public required init?(coder: NSCoder) {
        super.init(coder:coder)
    }

    #elseif os(iOS)

    override open func layoutSubviews() {
        super.layoutSubviews()
        updateWaveform()
    }

    #endif





}

fileprivate extension WaveformImageView {
    func updateWaveform() {
        guard let audioURL = waveformAudioURL else { return }
            self.image = waveformImageDrawer.waveformImage(fromAudioAt: audioURL, size: bounds.size, color: waveformColor,
                                                      style: waveformStyle, position: waveformPosition,
                                                      scale: mainScreenScale)

    }
}
