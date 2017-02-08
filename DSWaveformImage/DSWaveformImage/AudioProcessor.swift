//
// see
// * http://www.davidstarke.com/2015/04/waveforms.html
// * http://stackoverflow.com/questions/28626914/can-someone-explain-how-this-code-converts-volume-to-decibels-using-the-accelera
// for very good explanations of the asset reading and processing path
//

import Foundation
import Accelerate
import AVFoundation

struct AudioProcessor {
    func waveformSamples(from configuration: WaveformConfiguration) -> [Float]? {
        guard let assetReader = try? AVAssetReader(asset: configuration.audioAsset),
              let audioTrack = configuration.audioAsset.tracks.first else {
            return nil
        }

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings())
        assetReader.add(trackOutput)

        let requiredNumberOfSamples = Int(ceil(configuration.size.width * configuration.scale))
        let samples = extract(samplesFrom: assetReader, downsampledTo: requiredNumberOfSamples)

        switch assetReader.status {
        case .completed:
            return normalize(samples)
        default:
            print("ERROR: reading waveform audio data has failed \(assetReader.status)")
            return nil
        }
    }
}

// MARK: - Private

extension AudioProcessor {
    private var silenceDbThreshold: Float { return -50.0 } // everything below -50 dB will be clipped

    fileprivate func extract(samplesFrom assetReader: AVAssetReader, downsampledTo targetSampleCount: Int) -> [Float] {
        var outputSamples = [Float]()

        assetReader.startReading()
        while assetReader.status == .reading {
            let trackOutput = assetReader.outputs.first!

            if let sampleBuffer = trackOutput.copyNextSampleBuffer(),
                let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let blockBufferLength = CMBlockBufferGetDataLength(blockBuffer)
                var data = Data(capacity: blockBufferLength)
                data.withUnsafeMutableBytes { (blockSamples: UnsafeMutablePointer<Int16>) in
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, blockBufferLength, blockSamples)
                    CMSampleBufferInvalidate(sampleBuffer)

                    let processedSamples = process(blockSamples,
                                                   ofLength: blockBufferLength,
                                                   from: assetReader,
                                                   downsampledTo: targetSampleCount)
                    outputSamples += processedSamples
                }
            }
        }
        return outputSamples
    }

    fileprivate func normalize(_ samples: [Float]) -> [Float] {
        return samples.map { $0 / silenceDbThreshold }
    }

    private func process(_ samples: UnsafeMutablePointer<Int16>,
                         ofLength sampleLength: Int,
                         from assetReader: AVAssetReader,
                         downsampledTo targetSampleCount: Int) -> [Float] {
        var loudestClipValue: Float = 0.0
        var quietestClipValue = silenceDbThreshold
        var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
        let samplesToProcess = vDSP_Length(sampleLength / MemoryLayout<Int16>.size)

        var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
        vDSP_vflt16(samples, 1, &processingBuffer, 1, samplesToProcess)
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, samplesToProcess)
        vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, samplesToProcess, 1)
        vDSP_vclip(processingBuffer, 1, &quietestClipValue, &loudestClipValue, &processingBuffer, 1, samplesToProcess)

        let samplesPerPixel = sampleCount(from: assetReader) / targetSampleCount
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        let downSampledLength = Int(samplesToProcess) / samplesPerPixel
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)

        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter,
                    &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))

        return downSampledData
    }

    // swiftlint:disable force_cast
    private func sampleCount(from assetReader: AVAssetReader) -> Int {
        let audioTrack = (assetReader.outputs.first as? AVAssetReaderTrackOutput)?.track

        var sampleCount = 0
        audioTrack?.formatDescriptions.forEach { formatDescription in
            let audioDescription = CFBridgingRetain(formatDescription) as! CMAudioFormatDescription
            if let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioDescription) {
                sampleCount = Int(assetReader.asset.duration.value) * Int(basicDescription.pointee.mChannelsPerFrame)
                print("bits per channel: \(basicDescription.pointee.mBitsPerChannel)")
                print("bytes per frame: \(basicDescription.pointee.mBytesPerFrame)")
            }
        }
        return sampleCount
    }
    // swiftlint:enable force_cast
}

// MARK: - Configuration

fileprivate extension AudioProcessor {
    fileprivate func outputSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }
}
