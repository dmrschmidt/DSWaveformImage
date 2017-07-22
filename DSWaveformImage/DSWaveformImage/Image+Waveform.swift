import Foundation

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

public extension Image {

    public static func from(waveform: Waveform, configuration: WaveformConfiguration)->Image?{
        let waveformImageDrawer = WaveformImageDrawer()
        return waveformImageDrawer.waveformImage(from: waveform, with: configuration)
    }
}
