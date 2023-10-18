import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct SwiftUIExampleView: View {
    private enum ActiveTab: Hashable {
        case recorder, shape, overview
    }

    private static let colors = [UIColor.systemPink, UIColor.systemBlue, UIColor.systemGreen]
    private static var randomColor: UIColor { colors.randomElement()! }

    private static var audioURLs: [URL?] = [
        Bundle.main.url(forResource: "example_sound", withExtension: "m4a"),
        Bundle.main.url(forResource: "example_sound_2", withExtension: "m4a")
    ]
    private static func randomURL(_ current: URL?) -> URL? { audioURLs.filter { $0 != current }.randomElement()! }

    @StateObject private var audioRecorder: AudioRecorder = AudioRecorder()

    @State private var configuration: Waveform.Configuration = Waveform.Configuration(
        style: .striped(Waveform.Style.StripeConfig(color: Self.randomColor, width: 3, lineCap: .round)),
        verticalScalingFactor: 0.9
    )

    @State private var liveConfiguration: Waveform.Configuration = Waveform.Configuration(
        style: .striped(.init(color: randomColor, width: 3, spacing: 3))
    )

    @State private var audioURL: URL? = audioURLs.first!
    @State private var samples: [Float] = []
    @State private var silence: Bool = true
    @State private var selection: ActiveTab = .overview

    var body: some View {
        VStack {
            Text("SwiftUI examples")
                .font(.largeTitle.bold())

            Picker("Hey", selection: $selection) {
                Text("Recorder").tag(ActiveTab.recorder)
                Text("Shape").tag(ActiveTab.shape)
                Text("Overview").tag(ActiveTab.overview)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch selection {
            case .recorder: recordingExample
            case .shape: shape
            case .overview: overview
            }
        }
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private var recordingExample: some View {
        VStack {
            WaveformLiveCanvas(
                samples: audioRecorder.samples,
                configuration: liveConfiguration,
                renderer: CircularWaveformRenderer(kind: .circle),
                shouldDrawSilencePadding: silence
            )

            Toggle("draw silence", isOn: $silence)
                .controlSize(.mini)
                .padding(.horizontal)

            RecordingIndicatorView(
                samples: audioRecorder.samples,
                duration: audioRecorder.recordingTime,
                shouldDrawSilence: silence,
                isRecording: $audioRecorder.isRecording
            )
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var shape: some View {
        VStack {
            Text("WaveformView").font(.monospaced(.title.bold())())

            HStack {
                Button {
                    configuration = configuration.with(style: .striped(Waveform.Style.StripeConfig(color: Self.randomColor, width: 3, lineCap: .round)))
                    liveConfiguration = liveConfiguration.with(style: .striped(.init(color: Self.randomColor, width: 3, spacing: 3)))
                } label: {
                    Label("color", systemImage: "dice")
                        .frame(maxWidth: .infinity)
                }
                .font(.body.bold())
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Button {
                    audioURL = Self.randomURL(audioURL)
                    print("will draw \(audioURL!)")
                } label: {
                    Label("waveform", systemImage: "dice")
                        .frame(maxWidth: .infinity)
                }
                .font(.body.bold())
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // the if let is left here intentionally to illustrate how to deal with optional URLs
            // as this was asked in an older GitHub issue
            if let audioURL {
                WaveformView(audioURL: audioURL, configuration: configuration)

                WaveformView(
                    audioURL: audioURL,
                    configuration: configuration,
                    renderer: CircularWaveformRenderer(kind: .ring(0.7))
                ) { shape in
                    // you may completely override the shape styling this way
                    shape
                        .stroke(
                            LinearGradient(colors: [.red, Color(Self.randomColor)], startPoint: .zero, endPoint: .topTrailing),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                Divider()
                Text("WaveformShape").font(.monospaced(.title.bold())())

                /// **Note:** It's possible, but discouraged to use WaveformShape directly.
                /// As Shapes should not do any expensive computations, the analyzing should happen outside,
                /// hence making the API a tiny bit clumsy if used directly, since we do require to know the size,
                /// even though the Shape of course intrinsically knows its size already.
                GeometryReader { geometry in
                    WaveformShape(samples: samples)
                        .fill(Color.orange)
                        .task {
                            do {
                                let samplesNeeded = Int(geometry.size.width * configuration.scale)
                                let samples = try await WaveformAnalyzer().samples(fromAudioAt: audioURL, count: samplesNeeded)
                                await MainActor.run { self.samples = samples }
                            } catch {
                                assertionFailure(error.localizedDescription)
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var overview: some View {
        if let audioURL {
            HStack {
                VStack {
                    WaveformView(audioURL: audioURL, configuration: .init(style: .filled(.red)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .outlined(.blue, 0.5)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .gradient([.yellow, .orange])))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .gradientOutlined([.yellow, .orange], 1)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .striped(.init(color: .red, width: 2, spacing: 1))))

                    WaveformView(audioURL: audioURL, configuration: .init(style: .striped(.init(color: .black)))) { shape in
                        shape // override the shape styling
                            .stroke(LinearGradient(colors: [.blue, .pink], startPoint: .bottom, endPoint: .top), lineWidth: 3)
                    } placeholder: {
                        ProgressView()
                    }
                }

                VStack {
                    WaveformView(audioURL: audioURL, configuration: .init(style: .filled(.red)), renderer: CircularWaveformRenderer())
                    WaveformView(audioURL: audioURL, configuration: .init(style: .outlined(.blue, 0.5)), renderer: CircularWaveformRenderer())
                    WaveformView(audioURL: audioURL, configuration: .init(style: .gradient([.yellow, .orange])), renderer: CircularWaveformRenderer())
                    WaveformView(audioURL: audioURL, configuration: .init(style: .gradientOutlined([.yellow, .orange], 1)), renderer: CircularWaveformRenderer())
                    WaveformView(audioURL: audioURL, configuration: .init(style: .striped(.init(color: .red, width: 2, spacing: 2))), renderer: CircularWaveformRenderer())

                    WaveformView(audioURL: audioURL, configuration: .init(style: .striped(.init(color: .black))), renderer: CircularWaveformRenderer()) { shape in
                        shape // override the shape styling
                            .stroke(LinearGradient(colors: [.blue, .pink], startPoint: .bottom, endPoint: .top), lineWidth: 3)
                    } placeholder: {
                        ProgressView()
                    }
                }

                VStack {
                    WaveformView(audioURL: audioURL, configuration: .init(style: .filled(.red)), renderer: CircularWaveformRenderer(kind: .ring(0.5)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .outlined(.blue, 0.5)), renderer: CircularWaveformRenderer(kind: .ring(0.5)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .gradient([.yellow, .orange])), renderer: CircularWaveformRenderer(kind: .ring(0.5)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .gradientOutlined([.yellow, .orange], 1)), renderer: CircularWaveformRenderer(kind: .ring(0.5)))
                    WaveformView(audioURL: audioURL, configuration: .init(style: .striped(.init(color: .red, width: 2, spacing: 2))), renderer: CircularWaveformRenderer(kind: .ring(0.5)))

                    WaveformView(audioURL: audioURL, configuration: .init(style: .striped(.init(color: .black))), renderer: CircularWaveformRenderer(kind: .ring(0.5))) { shape in
                        shape // override the shape styling
                            .stroke(LinearGradient(colors: [.blue, .pink], startPoint: .bottom, endPoint: .top), lineWidth: 3)
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
        }
    }
}

struct SwiftUIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIExampleView()
    }
}

private class AudioRecorder: NSObject, ObservableObject, RecordingDelegate {
    @Published var samples: [Float] = []
    @Published var recordingTime: TimeInterval = 0
    @Published var isRecording: Bool = false {
        didSet {
            guard oldValue != isRecording else { return }
            isRecording ? startRecording() : stopRecording()
        }
    }

    private let audioManager: SCAudioManager

    override init() {
        audioManager = SCAudioManager()

        super.init()

        audioManager.prepareAudioRecording()
        audioManager.recordingDelegate = self
    }

    func startRecording() {
        samples = []
        audioManager.startRecording()
        isRecording = true
    }

    func stopRecording() {
        audioManager.stopRecording()
        isRecording = false
    }

    // MARK: - RecordingDelegate

    func audioManager(_ manager: SCAudioManager!, didAllowRecording flag: Bool) {}

    func audioManager(_ manager: SCAudioManager!, didFinishRecordingSuccessfully flag: Bool) {}

    func audioManager(_ manager: SCAudioManager!, didUpdateRecordProgress progress: CGFloat) {
        let linear = 1 - pow(10, manager.lastAveragePower() / 20)

        // Here we add the same sample 3 times to speed up the animation.
        // Usually you'd just add the sample once.
        recordingTime = audioManager.currentRecordingTime
        samples += [linear, linear, linear]
    }
}

