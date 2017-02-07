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
    private var silenceDbThreshold: Float { return -50.0 } // everything below -50 dB will be clipped

    func waveformSamples(from configuration: WaveformConfiguration) -> [Float]? {
        guard let assetReader = try? AVAssetReader(asset: configuration.audioAsset),
            let audioTrack = configuration.audioAsset.tracks.first else {
                return nil
        }
        
        print("before: \(configuration.audioAsset.duration)")
        
        audioTrack.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = audioTrack.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded: print("now: \(configuration.audioAsset.duration)")
            case .failed, .cancelled, .loading, .unknown: break
            }
        }

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings())
        assetReader.add(trackOutput)

        let requiredNumberOfSamples = Int(ceil(configuration.size.width * configuration.scale))
        let samples = extract(samplesFrom: assetReader,
                              downsampledTo: requiredNumberOfSamples,
                              with: channelCount(audioTrack:audioTrack))

        if assetReader.status == .failed || assetReader.status == .unknown {
            print("ERROR: reading waveform audio data has failed")
            return nil
        }

        if assetReader.status == .completed {
            let samplesPerPixel = samples.count// / requiredNumberOfSamples
            let normalizedSamples = normalize(samples, downsampledBy: samplesPerPixel)
            return normalizedSamples
        }

        return nil
    }

    private func normalize(_ samples: [Float], downsampledBy samplesPerPixel: Int) -> [Float] {
        var maxValue = silenceDbThreshold
        //        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        //        let downSampledLength = samples.count / samplesPerPixel
        //        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
        var normalizedSamples = [Float]()

        //        vDSP_desamp(samples,
        //                    vDSP_Stride(samplesPerPixel),
        //                    filter,
        //                    &downSampledData,
        //                    vDSP_Length(downSampledLength),
        //                    vDSP_Length(samplesPerPixel))

        for sample in samples {
            let normalizedSample = sample / maxValue
            normalizedSamples.append(normalizedSample)
        }

        return normalizedSamples
    }

    // swiftlint:disable force_cast
    private func channelCount(audioTrack: AVAssetTrack) -> Int {
        var channelCount = 0
        audioTrack.formatDescriptions.forEach { formatDescription in
            let audioDescription = CFBridgingRetain(formatDescription) as! CMAudioFormatDescription
            if let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioDescription) {
                channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
                basicDescription.pointee.mSampleRate
            }
        }
        return channelCount
    }
    // swiftlint:enable force_cast

    private func extract(samplesFrom assetReader: AVAssetReader,
                         downsampledTo targetSampleSize: Int,
                         with channelCount: Int) -> [Float] {
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

                    let processedSamples = process(blockSamples, sampleCount: blockBufferLength, downsampledTo: targetSampleSize)
                    outputSamples += processedSamples
                }
            }
        }
        return outputSamples
    }
    
    // for now, AVURLAssetDuration seems to be the amount of samples
    // and timescale the sampling rate; but later do it like line 49 in FDWaveform
    //
    // AVURLAssetDuration.duration  -> number of samples         (414720)
    // AVURLAssetDuration.timescale -> sampling rate              (44100)
    // mSampleRate                  -> definitely sample rate
    // total size of buffer          = number of samples * number of channels (2)

    private func process(_ samples: UnsafeMutablePointer<Int16>,
                         sampleCount: Int,
                         downsampledTo targetSampleSize: Int) -> [Float] {
        var ceil: Float = 0.0
        var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
        var silenceDbThresholdFloat = Float(silenceDbThreshold)
        let samplesToProcess = sampleCount / MemoryLayout<Int16>.size // really? not just sampleCount?
        let sampleCount = vDSP_Length(samplesToProcess)

        var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
        vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
        vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, sampleCount, 1)
        vDSP_vclip(processingBuffer, 1, &silenceDbThresholdFloat, &ceil, &processingBuffer, 1, sampleCount)

        // downsample and average
        let samplesPerPixel = 414720 * 2 / targetSampleSize
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        var downSampledLength = Int(samplesToProcess / samplesPerPixel)
        var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
        
        vDSP_desamp(processingBuffer,
                    vDSP_Stride(samplesPerPixel),
                    filter,
                    &downSampledData,
                    vDSP_Length(downSampledLength),
                    vDSP_Length(samplesPerPixel))
        
        return downSampledData
    }
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
