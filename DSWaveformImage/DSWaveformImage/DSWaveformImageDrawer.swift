// 
// see 
// * http://www.davidstarke.com/2015/04/waveforms.html
// * http://stackoverflow.com/questions/28626914/can-someone-explain-how-this-code-converts-volume-to-decibels-using-the-accelera
// for very good explanations of the asset reading and processing path
//

import Foundation
import Accelerate
import AVFoundation

private struct WaveformConfiguration {
    let audioAsset: AVURLAsset
    let color: UIColor
    let style: DSWaveformStyle
    let position: DSWaveformPosition
    let size: CGSize
    let scale: CGFloat
}

public struct DSWaveformImageDrawer {
    public init() { }

    // swiftlint:disable function_parameter_count
    public func waveformImage(fromAudio audioAsset: AVURLAsset,
                              color: UIColor,
                              style: DSWaveformStyle,
                              position: DSWaveformPosition,
                              size: CGSize,
                              scale: CGFloat) -> UIImage? {
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let configuration = WaveformConfiguration(audioAsset: audioAsset, color: color, style: style,
                                                  position: position, size: scaledSize, scale: scale)
        return renderWaveform(from: configuration)
    }

    public func waveformImage(fromAudioAt audioAssetURL: URL,
                              color: UIColor,
                              style: DSWaveformStyle,
                              position: DSWaveformPosition,
                              size: CGSize,
                              scale: CGFloat) -> UIImage? {
        let audioAsset = AVURLAsset(url: audioAssetURL)
        return waveformImage(fromAudio: audioAsset, color: color, style: style,
                             position: position, size: size, scale: scale)
    }
    // swiftlint:enable function_parameter_count
}

// TODO: extract into own class: gets audio URL, reads data and desamples to desired sample size
// MARK: - Audio File Processing

fileprivate extension DSWaveformImageDrawer {
    var silenceDbThreshold: Float { return -50.0 } // everything below -50 dB will be clipped

    fileprivate func waveformImageSamples(from configuration: WaveformConfiguration) -> [Float]? {
        guard let assetReader = try? AVAssetReader(asset: configuration.audioAsset),
            let audioTrack = configuration.audioAsset.tracks.first else {
                return nil
        }

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings())
        assetReader.add(trackOutput)

        let requiredNumberOfSamples = Int(ceil(configuration.size.width * configuration.scale)) + 500
        let samples = readProcessedSamples(from: assetReader, of: requiredNumberOfSamples)

        if assetReader.status == .failed || assetReader.status == .unknown {
            print("ERROR: reading waveform audio data has failed")
            return nil
        }

        if assetReader.status == .completed {
            let samplesPerPixel = samples.count * channelCount(audioTrack:audioTrack) / requiredNumberOfSamples
            let normalizedSamples = normalize(samples, downsampledBy: samplesPerPixel)
            return normalizedSamples
        }

        return nil
    }

    fileprivate func normalize(_ samples: [Float], downsampledBy samplesPerPixel: Int) -> [Float] {
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
            }
        }
        return channelCount
    }
    // swiftlint:enable force_cast

    private func readProcessedSamples(from assetReader: AVAssetReader, of targetSampleSize: Int) -> [Float] {
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

                    let processedSamples = process(blockSamples, sampleCount: blockBufferLength)
                    outputSamples += processedSamples
                }
            }
        }
        return outputSamples
    }

    private func process(_ samples: UnsafeMutablePointer<Int16>, sampleCount: Int) -> [Float] {
        var ceil: Float = 0.0
        var zeroDbEquivalent: Float = Float(Int16.max) // maximum amplitude storable in Int16 = 0 Db (loudest)
        var silenceDbThresholdFloat = Float(silenceDbThreshold)
        let samplesToProcess = sampleCount / MemoryLayout<Int16>.size
        let sampleCount = vDSP_Length(samplesToProcess)

        var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
        vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
        vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
        vDSP_vdbcon(processingBuffer, 1, &zeroDbEquivalent, &processingBuffer, 1, sampleCount, 1)
        vDSP_vclip(processingBuffer, 1, &silenceDbThresholdFloat, &ceil, &processingBuffer, 1, sampleCount)

        return processingBuffer
    }
}

// MARK: Image generation

fileprivate extension DSWaveformImageDrawer {
    fileprivate func renderWaveform(from configuration: WaveformConfiguration) -> UIImage? {
        guard let imageSamples = waveformImageSamples(from: configuration) else { return nil }
        return graphImage(from: imageSamples, with: configuration)
    }

    private func graphImage(from samples: [Float], with configuration: WaveformConfiguration) -> UIImage? {
        UIGraphicsBeginImageContext(configuration.size)
        let context = UIGraphicsGetCurrentContext()!

        drawGraph(from: samples, on: context, with: configuration)

        let graphImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return graphImage
    }

    private func drawGraph(from samples: [Float],
                           on context: CGContext,
                           with configuration: WaveformConfiguration) {
        let graphRect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let graphCenter = graphRect.size.height / 2.0
        let positionAdjustedGraphCenter = graphCenter + CGFloat(configuration.position.rawValue) * graphCenter
        let verticalPaddingDivisor = CGFloat(configuration.position == .middle ? 2.5 : 1.5) // 2 = 50 % of height
        let drawMappingFactor = graphRect.size.height / verticalPaddingDivisor
        let minimumGraphAmplitude: CGFloat = 1 // we want to see at least a 1pt line for silence

        let path = CGMutablePath()
        var maxAmplitude: CGFloat = 0.0 // we know 1 is our max in normalized data, but we keep it 'generic'
        context.setLineWidth(1.0)
        for (x, sample) in samples.enumerated() {
            let invertedDbSample = 1 - CGFloat(sample) // since sample is in dB, linearly normalized to [0, 1] (1 -> -50 dB)
            let drawingAmplitude = max(minimumGraphAmplitude, invertedDbSample * drawMappingFactor)
            let drawingAmplitudeUp = positionAdjustedGraphCenter - drawingAmplitude
            let drawingAmplitudeDown = positionAdjustedGraphCenter + drawingAmplitude
            maxAmplitude = max(drawingAmplitude, maxAmplitude)

            if configuration.style == .striped && (x % 5 != 0) { continue }

            path.move(to: CGPoint(x: CGFloat(x), y: drawingAmplitudeUp))
            path.addLine(to: CGPoint(x: CGFloat(x), y: drawingAmplitudeDown))
        }
        context.addPath(path)

        switch configuration.style {
        case .filled, .striped:
            context.setStrokeColor(configuration.color.cgColor)
            context.strokePath()
        case .gradient:
            context.replacePathWithStrokedPath()
            context.clip()
            let colors = NSArray(array: [
                configuration.color.cgColor,
                configuration.color.highlighted(brightnessAdjustment: 0.5).cgColor
            ]) as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: nil)!
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: 0, y: positionAdjustedGraphCenter - maxAmplitude),
                                       end: CGPoint(x: 0, y: positionAdjustedGraphCenter + maxAmplitude),
                                       options: .drawsAfterEndLocation)
        }
    }
}

// MARK: - Configuration

fileprivate extension DSWaveformImageDrawer {
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
