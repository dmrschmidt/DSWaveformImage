import AVFoundation

public enum WaveformPosition: Int {
    case top    = -1
    case middle =  0
    case bottom =  1
}

public enum WaveformStyle: Int {
    case filled = 0
    case gradient
    case striped
}

public struct WaveformConfiguration {
    let color: UIColor
    let style: WaveformStyle
    let position: WaveformPosition
    let size: CGSize
    let scale: CGFloat

    public init(color: UIColor, style: WaveformStyle, position: WaveformPosition, size: CGSize, scale: CGFloat) {
        self.color = color
        self.style = style
        self.position = position
        self.size = size
        self.scale = scale
    }
}
