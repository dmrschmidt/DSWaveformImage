import DSWaveformImage
import SwiftUI

@available(iOS 14.0, *)
struct SwiftUIExampleView: View {
    private static let colors = [UIColor.red, UIColor.blue, UIColor.green]
    private static var randomColor: UIColor {
        colors[Int.random(in: 0..<colors.count)]
    }

    @StateObject private var audioRecorder: AudioRecorder = AudioRecorder()
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "wav")!

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
            Text("This is a very basic SwiftUI usage example.\nSee `WaveformImageViewUI`.")
                .multilineTextAlignment(.center).padding()
            Button {
                configuration = configuration.with(style: .filled(Self.randomColor))
                liveConfiguration = liveConfiguration.with(style: .striped(.init(color: Self.randomColor, width: 3, spacing: 3)))
            } label: {
                Text("switch random color")
            }

            WaveformImageViewUI(audioURL: audioURL, configuration: configuration)

            if #available(iOS 15.0, *) {
                WaveformLiveCanvas(
                    samples: $audioRecorder.samples,
                    configuration: $liveConfiguration,
                    shouldDrawSilencePadding: .constant(true)
                )
            } else {
                Text("WaveformLiveCanvas requires iOS 15.0")
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            audioRecorder.startRecording()
        }
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

    private let audioManager: SCAudioManager

    override init() {
        audioManager = SCAudioManager()

        super.init()

        audioManager.prepareAudioRecording()
        audioManager.recordingDelegate = self
    }

    func startRecording() {
        audioManager.startRecording()
    }

    // MARK: - RecordingDelegate

    func audioManager(_ manager: SCAudioManager!, didAllowRecording flag: Bool) {}

    func audioManager(_ manager: SCAudioManager!, didFinishRecordingSuccessfully flag: Bool) {}

    func audioManager(_ manager: SCAudioManager!, didUpdateRecordProgress progress: CGFloat) {
        let linear = 1 - pow(10, manager.lastAveragePower() / 20)

        // Here we add the same sample 3 times to speed up the animation.
        // Usually you'd just add the sample once.
        samples += [linear, linear, linear]
    }
}

