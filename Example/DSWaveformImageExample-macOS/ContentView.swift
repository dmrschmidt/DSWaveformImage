import SwiftUI
import DSWaveformImage
import DSWaveformImageViews

struct ContentView: View {
    private static let colors = [NSColor.systemPink, NSColor.systemBlue, NSColor.systemGreen]
    private static var randomColor: NSColor {
        colors[Int.random(in: 0..<colors.count)]
    }

    @State private var audioURL: URL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!

    @State var configuration: Waveform.Configuration = Waveform.Configuration(
        style: .gradient([.red, .green])
    )

    @StateObject var audioCoordinator = AudioCoordinator()

    var body: some View {
        VStack {
            Text("SwiftUI example")
                .font(.largeTitle.bold())

            Button {
                configuration = configuration.with(style: .striped(.init(color: Self.randomColor)))
                audioCoordinator.start()
            } label: {
                Label("switch color randomly", systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.body.bold())
            .padding()
            .background(Color(NSColor.systemGray).opacity(0.6))
            .cornerRadius(10)

            HStack {
                if #available(macOS 12.0, *) {
                    WaveformView(audioURL: audioURL, configuration: configuration, renderer: CircularWaveformRenderer())
                } else {
                    Text("at least macOS 12 is required")
                }

                FFTView(fftResults: audioCoordinator.fftResult)
                    .border(Color.black)
            }
        }
    }
}

class AudioCoordinator: ObservableObject {
    let audioRecorder = AudioRecorder()
    let audioAnalyzer = AudioAnalyzer()

    @Published var fftResult: [Float] = []

    func start() {
        audioRecorder.requestMicrophoneAccess()
        audioRecorder.register { audioBuffer in
            let result = self.audioAnalyzer.performFFT(buffer: audioBuffer)
            DispatchQueue.main.async { self.fftResult = result }
        }
    }
}

import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    var audioEngine = AVAudioEngine()
    var inputNode: AVAudioInputNode!
    var bufferFormat: AVAudioFormat!
    var observer: ((AVAudioPCMBuffer) -> Void)?

    override init() {
        super.init()
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        inputNode = audioEngine.inputNode
        bufferFormat = inputNode.inputFormat(forBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
            self?.processMicrophoneBuffer(buffer: buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine failed to start: \(error)")
        }
    }

    private func processMicrophoneBuffer(buffer: AVAudioPCMBuffer) {
        observer?(buffer)
    }

    func register(observer: @escaping (AVAudioPCMBuffer) -> Void) {
        self.observer = observer
    }

    func requestMicrophoneAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: // The user has previously granted access to the microphone.
            print("Microphone access previously authorized")
        case .notDetermined: // The user has not yet been asked for microphone access.
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    print("Microphone access granted")
                } else {
                    print("Microphone access denied")
                }
            }
        case .denied: // The user has previously denied access.
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    print("Microphone access granted")
                } else {
                    print("Microphone access denied")
                }
            }
            print("Microphone access denied")
        case .restricted: // The user can't grant access due to restrictions.
            print("Microphone access restricted")
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }
}

import Accelerate

class AudioAnalyzer {
    func performFFT(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let floatChannelData = buffer.floatChannelData else {
            return []
        }

        let frameCount = buffer.frameLength
        let log2n = UInt(log2f(Float(frameCount)))
        let bufferSizePOT = 1 << log2n
        let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))

        let halfBufferSize = Int(bufferSizePOT / 2)
        let realp = UnsafeMutablePointer<Float>.allocate(capacity: halfBufferSize)
        let imagp = UnsafeMutablePointer<Float>.allocate(capacity: halfBufferSize)

        defer {
            realp.deallocate()
            imagp.deallocate()
        }

        realp.initialize(repeating: 0, count: halfBufferSize)
        imagp.initialize(repeating: 0, count: halfBufferSize)

        var complex = DSPSplitComplex(realp: realp, imagp: imagp)

        // Apply window function here
        let windowSize = Int(frameCount)
        var window = [Float](repeating: 0, count: windowSize)
        vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
        var windowedSignal = [Float](repeating: 0, count: windowSize)
        vDSP_vmul(floatChannelData.pointee, 1, window, 1, &windowedSignal, 1, vDSP_Length(windowSize))

        windowedSignal.withUnsafeMutableBytes {
            vDSP_ctoz($0.baseAddress!.assumingMemoryBound(to: DSPComplex.self), 2, &complex, 1, UInt(halfBufferSize))
        }

        vDSP_fft_zrip(fftSetup!, &complex, 1, log2n, FFTDirection(FFT_FORWARD))

        // Convert complex FFT output to magnitudes
        var magnitudes = [Float](repeating: 0.0, count: halfBufferSize)
        var magnitudesNormalized = [Float](repeating: 0.0, count: halfBufferSize)
        vDSP_zvmags(&complex, 1, &magnitudes, 1, vDSP_Length(halfBufferSize))

        // Normalize the magnitudes
        var normFactor = 1.0 / Float(2 * bufferSizePOT)
        vDSP_vsmul(&magnitudes, 1, &normFactor, &magnitudesNormalized, 1, vDSP_Length(halfBufferSize))

        // Clean up
        vDSP_destroy_fftsetup(fftSetup)

        return magnitudesNormalized
    }
}

struct FFTView: View {
    var fftResults: [Float] // Assuming fftResults is already populated with the magnitudes from FFT
    var sampleRate: Float = 44100 // The sample rate of the audio signal

    // Function to convert Hertz to Mel
    private func hzToMel(hz: Float) -> Float {
        return 2595 * log10(1 + hz / 700)
    }

    let maxDB: Float = 80.0
    let minDB: Float = -32.0

    // Function to convert linear FFT bins to Mel scale
    private func convertToMelScale(fftResults: [Float]) -> [Float] {
        let numMelBins = fftResults.count // Use the same number of bins for simplicity
        let maxHz = sampleRate / 2
        let maxMel = hzToMel(hz: maxHz)

        // Create an array of Mel frequencies
        let melBinEdges = (0...numMelBins).map { maxMel / Float(numMelBins) * Float($0) }
        // Convert Mel frequencies back to Hz
        let binEdgesHz = melBinEdges.map { 700 * (pow(10, $0 / 2595) - 1) }
        // Map the magnitudes to the Mel scale
        var melMagnitudes = [Float](repeating: 0, count: numMelBins)
        for (index, edge) in binEdgesHz.enumerated() where index < numMelBins {
            let lowerEdge = edge
            let upperEdge = binEdgesHz[min(index + 1, binEdgesHz.count - 1)]

            // Find the corresponding FFT bins for these edges
            let lowerBin = Int(lowerEdge / (sampleRate / Float(fftResults.count)))
            let upperBin = min(Int(upperEdge / (sampleRate / Float(fftResults.count))), fftResults.count - 1)

            // Sum the magnitudes in this range
            let sum = fftResults[lowerBin...upperBin].reduce(0, +)
            melMagnitudes[index] = sum / Float(upperBin - lowerBin + 1) // Average the magnitudes
        }

        return melMagnitudes
    }

    func toDB(_ inMagnitude: Float) -> Float {
        // ceil to 128db in order to avoid log10'ing 0
        let magnitude = max(inMagnitude, Float.leastNormalMagnitude)
        return 10 * log10f(magnitude)
    }

    var body: some View {
        GeometryReader { geometry in
            let melResults = convertToMelScale(fftResults: fftResults)
            let headroom = maxDB - minDB

            Path { path in
                for i in melResults.indices {
                    var magnitudeDB = toDB(melResults[i])

                    // Normalize the incoming magnitude so that -Inf = 0
                    magnitudeDB = max(0, magnitudeDB + abs(minDB))

                    let dbRatio = min(1.0, magnitudeDB / headroom)
                    let magnitudeNorm = CGFloat(dbRatio) * geometry.size.height

                    let x = geometry.size.width * CGFloat(i) / CGFloat(melResults.count)
                    let y = geometry.size.height - magnitudeNorm

                    if i == 0 {
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .fill(.linearGradient(colors: [.blue, .green, .orange, .red], startPoint: .bottom, endPoint: .top))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
