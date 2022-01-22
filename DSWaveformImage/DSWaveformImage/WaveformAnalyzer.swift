//
// see
// * http://www.davidstarke.com/2015/04/waveforms.html
// * http://stackoverflow.com/questions/28626914
// for very good explanations of the asset reading and processing path
//
// FFT done using: https://github.com/jscalo/tempi-fft
//

import Foundation
import Accelerate
import AVFoundation

struct WaveformAnalysis {
    let amplitudes: [Float]
    let fft: [TempiFFT]?
}

/// Calculates the waveform of the initialized asset URL.
public class WaveformAnalyzer {
    public enum AnalyzeError: Error { case generic }

    /// Everything below this noise floor cutoff will be clipped and interpreted as silence. Default is `-50.0`.
    public var noiseFloorDecibelCutoff: Float = -50.0

    private let assetReader: AVAssetReader
    private let audioAssetTrack: AVAssetTrack

    public init?(audioAssetURL: URL) {
        let audioAsset = AVURLAsset(url: audioAssetURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

        guard
                let assetReader = try? AVAssetReader(asset: audioAsset),
                let assetTrack = audioAsset.tracks(withMediaType: .audio).first else {
            print("ERROR loading asset / audio track")
            return nil
        }

        self.assetReader = assetReader
        self.audioAssetTrack = assetTrack
    }

#if compiler(>=5.5) && canImport(_Concurrency)
    /// Calculates the amplitude envelope of the initialized audio asset URL, downsampled to the required `count` amount of samples.
    /// Calls the completionHandler on a background thread.
    /// - Parameter count: amount of samples to be calculated. Downsamples.
    /// - Parameter qos: QoS of the DispatchQueue the calculations are performed (and returned) on.
    ///
    /// Returns sampled result or nil in edge-error cases.
    @available(iOS 13, *)
    public func samples(count: Int, qos: DispatchQoS.QoSClass = .userInitiated) async throws -> [Float] {
        try await withCheckedThrowingContinuation { continuation in
            waveformSamples(count: count, qos: qos, fftBands: nil) { analysis in
                if let amplitudes = analysis?.amplitudes {
                    continuation.resume(with: .success(amplitudes))
                } else {
                    continuation.resume(with: .failure(AnalyzeError.generic))
                }
            }
        }
    }
#endif

    /// Calculates the amplitude envelope of the initialized audio asset URL, downsampled to the required `count` amount of samples.
    /// Calls the completionHandler on a background thread.
    /// - Parameter count: amount of samples to be calculated. Downsamples.
    /// - Parameter qos: QoS of the DispatchQueue the calculations are performed (and returned) on.
    /// - Parameter completionHandler: called from a background thread. Returns the sampled result or nil in edge-error cases.
    public func samples(count: Int, qos: DispatchQoS.QoSClass = .userInitiated, completionHandler: @escaping (_ amplitudes: [Float]?) -> ()) {
        waveformSamples(count: count, qos: qos, fftBands: nil) { analysis in
            completionHandler(analysis?.amplitudes)
        }
    }
}

// MARK: - Private

fileprivate extension WaveformAnalyzer {
    func waveformSamples(
            count requiredNumberOfSamples: Int,
            qos: DispatchQoS.QoSClass,
            fftBands: Int?,
            completionHandler: @escaping (_ analysis: WaveformAnalysis?) -> ()) {
        guard requiredNumberOfSamples > 0 else {
            completionHandler(nil)
            return
        }

        let trackOutput = AVAssetReaderTrackOutput(track: audioAssetTrack, outputSettings: outputSettings())
        assetReader.add(trackOutput)

        assetReader.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = self.assetReader.asset.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded:
                let totalSamples = self.totalSamplesOfTrack()
                DispatchQueue.global(qos: qos).async {
                    let analysis = self.extract(totalSamples: totalSamples, downsampledTo: requiredNumberOfSamples, fftBands: fftBands)

                    switch self.assetReader.status {
                    case .completed:
                        completionHandler(analysis)
                    default:
                        print("ERROR: reading waveform audio data has failed \(self.assetReader.status)")
                        completionHandler(nil)
                    }
                }

            case .failed, .cancelled, .loading, .unknown:
                print("failed to load due to: \(error?.localizedDescription ?? "unknown error")")
                completionHandler(nil)
            @unknown default:
                print("failed to load due to: \(error?.localizedDescription ?? "unknown error")")
                completionHandler(nil)
            }
        }
    }

    func extract(totalSamples: Int,
                 downsampledTo targetSampleCount: Int,
                 fftBands: Int?) -> WaveformAnalysis {
        var outputSamples = [Float]()
        var outputFFT = fftBands == nil ? nil : [TempiFFT]()
        var sampleBuffer = Data()
        var sampleBufferFFT = Data()

        // read upfront to avoid frequent re-calculation (and memory bloat from C-bridging)
        let samplesPerPixel = max(1, totalSamples / targetSampleCount)
        let samplesPerFFT = 4096 // ~100ms at 44.1kHz, rounded to closest pow(2) for FFT

        self.assetReader.startReading()
        while self.assetReader.status == .reading {
            let trackOutput = assetReader.outputs.first!

            guard let nextSampleBuffer = trackOutput.copyNextSampleBuffer(),
                let blockBuffer = CMSampleBufferGetDataBuffer(nextSampleBuffer) else {
                    break
            }

            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>? = nil
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: &readBufferLength, totalLengthOut: nil, dataPointerOut: &readBufferPointer)
            sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            if fftBands != nil {
                // don't append data to this buffer unless we're going to use it.
                sampleBufferFFT.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            }
            CMSampleBufferInvalidate(nextSampleBuffer)

            let processedSamples = process(sampleBuffer, from: assetReader, downsampleTo: samplesPerPixel)
            outputSamples += processedSamples

            if processedSamples.count > 0 {
                // vDSP_desamp uses strides of samplesPerPixel; remove only the processed ones
                sampleBuffer.removeFirst(processedSamples.count * samplesPerPixel * MemoryLayout<Int16>.size)

                // this takes care of a memory leak where Memory continues to increase even though it should clear after calling .removeFirst(…) above.
                sampleBuffer = Data(sampleBuffer)
            }

            if let fftBands = fftBands, sampleBufferFFT.count / MemoryLayout<Int16>.size >= samplesPerFFT {
                let processedFFTs = process(sampleBufferFFT, samplesPerFFT: samplesPerFFT, fftBands: fftBands)
                sampleBufferFFT.removeFirst(processedFFTs.count * samplesPerFFT * MemoryLayout<Int16>.size)
                outputFFT? += processedFFTs
            }
        }

        // if we don't have enough pixels yet,
        // process leftover samples with padding (to reach multiple of samplesPerPixel for vDSP_desamp)
        if outputSamples.count < targetSampleCount {
            let missingSampleCount = (targetSampleCount - outputSamples.count) * samplesPerPixel
            let backfillPaddingSampleCount = missingSampleCount - (sampleBuffer.count / MemoryLayout<Int16>.size)
            let backfillPaddingSampleCount16 = backfillPaddingSampleCount * MemoryLayout<Int16>.size
            let backfillPaddingSamples = [UInt8](repeating: 0, count: backfillPaddingSampleCount16)
            sampleBuffer.append(backfillPaddingSamples, count: backfillPaddingSampleCount16)
            let processedSamples = process(sampleBuffer, from: assetReader, downsampleTo: samplesPerPixel)
            outputSamples += processedSamples
        }

        let targetSamples = Array(outputSamples[0..<targetSampleCount])
        return WaveformAnalysis(amplitudes: normalize(targetSamples), fft: outputFFT)
    }

    private func process(_ sampleBuffer: Data,
                         from assetReader: AVAssetReader,
                         downsampleTo samplesPerPixel: Int) -> [Float] {
        var downSampledData = [Float]()
        let sampleLength = sampleBuffer.count / MemoryLayout<Int16>.size

        // guard for crash in very long audio files
        guard sampleLength / samplesPerPixel > 0 else { return downSampledData }

        sampleBuffer.withUnsafeBytes { (samplesRawPointer: UnsafeRawBufferPointer) in
            let unsafeSamplesBufferPointer = samplesRawPointer.bindMemory(to: Int16.self)
            let unsafeSamplesPointer = unsafeSamplesBufferPointer.baseAddress!
            var loudestClipValue: Float = 0.0
            var quietestClipValue = noiseFloorDecibelCutoff
            var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
            let samplesToProcess = vDSP_Length(sampleLength)

            var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
            vDSP_vflt16(unsafeSamplesPointer, 1, &processingBuffer, 1, samplesToProcess) // convert 16bit int to float (
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, samplesToProcess) // absolute amplitude value
            vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, samplesToProcess, 1) // convert to DB
            vDSP_vclip(processingBuffer, 1, &quietestClipValue, &loudestClipValue, &processingBuffer, 1, samplesToProcess)

            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
            let downSampledLength = sampleLength / samplesPerPixel
            downSampledData = [Float](repeating: 0.0, count: downSampledLength)

            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter,
                        &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
        }

        return downSampledData
    }

    private func process(_ sampleBuffer: Data,
                         samplesPerFFT: Int,
                         fftBands: Int) -> [TempiFFT] {
        var ffts = [TempiFFT]()
        let sampleLength = sampleBuffer.count / MemoryLayout<Int16>.size
        sampleBuffer.withUnsafeBytes { (samplesRawPointer: UnsafeRawBufferPointer) in
            let unsafeSamplesBufferPointer = samplesRawPointer.bindMemory(to: Int16.self)
            let unsafeSamplesPointer = unsafeSamplesBufferPointer.baseAddress!
            let samplesToProcess = vDSP_Length(sampleLength)

            var processingBuffer = [Float](repeating: 0.0, count: Int(samplesToProcess))
            vDSP_vflt16(unsafeSamplesPointer, 1, &processingBuffer, 1, samplesToProcess) // convert 16bit int to float

            repeat {
                let fftBuffer = processingBuffer[0..<samplesPerFFT]
                let fft = TempiFFT(withSize: samplesPerFFT, sampleRate: 44100.0)
                fft.windowType = TempiFFTWindowType.hanning
                fft.fftForward(Array(fftBuffer))
                fft.calculateLinearBands(minFrequency: 0, maxFrequency: fft.nyquistFrequency, numberOfBands: fftBands)
                ffts.append(fft)

                processingBuffer.removeFirst(samplesPerFFT)
            } while processingBuffer.count >= samplesPerFFT
        }
        return ffts
    }

    func normalize(_ samples: [Float]) -> [Float] {
        return samples.map { $0 / noiseFloorDecibelCutoff }
    }

    // swiftlint:disable force_cast
    private func totalSamplesOfTrack() -> Int {
        var totalSamples = 0

        autoreleasepool {
            let descriptions = audioAssetTrack.formatDescriptions as! [CMFormatDescription]
            descriptions.forEach { formatDescription in
                guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else { return }
                let channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
                let sampleRate = basicDescription.pointee.mSampleRate
                let duration = Double(assetReader.asset.duration.value)
                let timescale = Double(assetReader.asset.duration.timescale)
                let totalDuration = duration / timescale
                totalSamples = Int(sampleRate * totalDuration) * channelCount
            }
        }

        return totalSamples
    }
    // swiftlint:enable force_cast
}

// MARK: - Configuration

private extension WaveformAnalyzer {
    func outputSettings() -> [String: Any] {
        return [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }
}
