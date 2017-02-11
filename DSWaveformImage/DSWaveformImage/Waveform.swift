import Foundation
import AVFoundation

public class Waveform {
    private let assetReader: AVAssetReader
    private let audioProcessor: AudioProcessor

    public init?(audioAsset: AVURLAsset) {
        guard let assetReader = try? AVAssetReader(asset: audioAsset),
              let _ = audioAsset.tracks.first else {
                return nil
        }

        self.assetReader = assetReader
        self.audioProcessor = AudioProcessor()
    }

    public convenience init?(audioAssetURL: URL) {
        let audioAsset = AVURLAsset(url: audioAssetURL)
        self.init(audioAsset: audioAsset)
    }

    public func samples(count: Int) -> [Float]? {
        return audioProcessor.waveformSamples(from: assetReader, count: count)
    }
}
