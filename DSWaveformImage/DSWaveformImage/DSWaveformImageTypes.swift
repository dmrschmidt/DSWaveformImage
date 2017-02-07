import AVFoundation

public enum DSWaveformPosition: Int {
    case top    = -1
    case middle =  0
    case bottom =  1
}

public enum DSWaveformStyle: Int {
    case filled = 0
    case gradient
    case striped
}

struct WaveformConfiguration {
    let audioAsset: AVURLAsset
    let color: UIColor
    let style: DSWaveformStyle
    let position: DSWaveformPosition
    let size: CGSize
    let scale: CGFloat
}
