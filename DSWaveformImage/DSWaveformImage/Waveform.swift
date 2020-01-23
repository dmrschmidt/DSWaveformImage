import Foundation
import AVFoundation

public class Waveform {
    private let assetReader: AVAssetReader
    private let audioAssetTrack: AVAssetTrack
    private let waveformAnalyzer: WaveformAnalyzer

    public init?(audioAssetURL: URL) {
        let audioAsset = AVURLAsset(url: audioAssetURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

        guard
                let assetReader = try? AVAssetReader(asset: audioAsset),
                let assetTrack = audioAsset.tracks(withMediaType: .audio).first else {
            return nil
        }

        self.assetReader = assetReader
        self.audioAssetTrack = assetTrack
        self.waveformAnalyzer = WaveformAnalyzer()
    }

    public func samples(count: Int, completionHandler: @escaping (_ analysis: [Float]?) -> ()) {
        waveformAnalyzer.waveformSamples(from: assetReader, audioTrack: audioAssetTrack, count: count, fftBands: nil) { analysis in
            completionHandler(analysis?.amplitudes)
        }
    }
}
