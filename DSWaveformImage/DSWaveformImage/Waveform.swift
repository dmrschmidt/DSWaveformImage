import Foundation
import AVFoundation

public class Waveform {
    private let assetReader: AVAssetReader
    private let waveformAnalyzer: WaveformAnalyzer

    public init?(audioAsset: AVURLAsset) {
        guard let assetReader = try? AVAssetReader(asset: audioAsset),
              let _ = audioAsset.tracks.first else {
                return nil
        }

        self.assetReader = assetReader
        self.waveformAnalyzer = WaveformAnalyzer()
    }

    public convenience init?(audioAssetURL: URL) {
        let audioAsset = AVURLAsset(url: audioAssetURL)
        self.init(audioAsset: audioAsset)
    }

    public func samples(count: Int) -> [Float]? {
        let screenWidth = Int(UIScreen.main.bounds.size.width * UIScreen.main.scale)
        return waveformAnalyzer.waveformSamples(from: assetReader, count: count, fftBands: screenWidth)?.amplitudes
    }
}
