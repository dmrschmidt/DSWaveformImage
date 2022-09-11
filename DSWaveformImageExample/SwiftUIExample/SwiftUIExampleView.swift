import DSWaveformImage
import SwiftUI

@available(iOS 14.0, *)
struct SwiftUIExampleView: View {
    private static let colors = [UIColor.systemPink, UIColor.systemBlue, UIColor.systemGreen]
    private static var randomColor: UIColor {
        colors[Int.random(in: 0..<colors.count)]
    }

    @StateObject private var audioRecorder: AudioRecorder = AudioRecorder()
    @State private var audioURL: URL = Bundle.main.url(forResource: "example_sound", withExtension: "wav")!

    @State var configuration: Waveform.Configuration = Waveform.Configuration(
        style: .filled(randomColor),
        position: .bottom
    )

    @State var liveConfiguration: Waveform.Configuration = Waveform.Configuration(
        style: .striped(.init(color: randomColor, width: 3, spacing: 3)),
        position: .middle
    )

    var body: some View {
        VStack {
            Text("SwiftUI examples")
                .font(.largeTitle.bold())

            Button {
                configuration = configuration.with(style: .filled(Self.randomColor))
                liveConfiguration = liveConfiguration.with(style: .striped(.init(color: Self.randomColor, width: 3, spacing: 3)))
            } label: {
                Label("switch color randomly", systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.body.bold())
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            if #available(iOS 15.0, *) {
                WaveformView(audioURL: $audioURL, configuration: $configuration)

                WaveformLiveCanvas(
                    samples: $audioRecorder.samples,
                    configuration: $liveConfiguration,
                    shouldDrawSilencePadding: .constant(true)
                )

                RecordingIndicatorView(
                    samples: audioRecorder.samples,
                    duration: audioRecorder.recordingTime,
                    isRecording: $audioRecorder.isRecording
                )
                    .padding()
            } else {
                Text("WaveformView & WaveformLiveCanvas require iOS 15.0")
            }
        }
        .padding(.vertical, 20)
    }
}

@available(iOS 15.0, *)
struct LiveRecordingView_Previews: PreviewProvider {
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

