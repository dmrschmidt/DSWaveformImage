//
// see
// * http://www.davidstarke.com/2015/04/waveforms.html
// * http://stackoverflow.com/questions/28626914
// for very good explanations of the asset reading and processing path
//

import Foundation
import Accelerate
import AVFoundation

struct AudioProcessor {
    func waveformSamples(from assetReader: AVAssetReader, count: Int) -> [Float]? {
        guard let audioTrack = assetReader.asset.tracks.first else {
            return nil
        }

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings())
        assetReader.add(trackOutput)

        let requiredNumberOfSamples = count
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
                let sampleLength = CMSampleBufferGetNumSamples(sampleBuffer) * channelCount(from: assetReader)
                var data = Data(capacity: blockBufferLength)
                data.withUnsafeMutableBytes { (blockSamples: UnsafeMutablePointer<Int16>) in
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, blockBufferLength, blockSamples)
                    CMSampleBufferInvalidate(sampleBuffer)

                    let processedSamples = process(blockSamples,
                                                   ofLength: sampleLength,
                                                   from: assetReader,
                                                   downsampledTo: targetSampleCount)
                    outputSamples += processedSamples
                }
            }
        }
        var paddedSamples = [Float](repeating: silenceDbThreshold, count: targetSampleCount)
        paddedSamples.replaceSubrange(0..<min(targetSampleCount, outputSamples.count), with: outputSamples)

        return paddedSamples
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
        let samplesToProcess = vDSP_Length(sampleLength)

        var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
        vDSP_vflt16(samples, 1, &processingBuffer, 1, samplesToProcess)
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, samplesToProcess)
        vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, samplesToProcess, 1)
        vDSP_vclip(processingBuffer, 1, &quietestClipValue, &loudestClipValue, &processingBuffer, 1, samplesToProcess)

        let samplesPerPixel = max(1, sampleCount(from: assetReader) / targetSampleCount)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        let downSampledLength = sampleLength / samplesPerPixel
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)

        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter,
                    &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))

        return downSampledData
    }

    private func sampleCount(from assetReader: AVAssetReader) -> Int {
        let samplesPerChannel = Int(assetReader.asset.duration.value)
        return samplesPerChannel * channelCount(from: assetReader)
    }

    // swiftlint:disable force_cast
    private func channelCount(from assetReader: AVAssetReader) -> Int {
        let audioTrack = (assetReader.outputs.first as? AVAssetReaderTrackOutput)?.track

        var channelCount = 0
        audioTrack?.formatDescriptions.forEach { formatDescription in
            let audioDescription = CFBridgingRetain(formatDescription) as! CMAudioFormatDescription
            if let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioDescription) {
                channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
            }
        }
        return channelCount
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
