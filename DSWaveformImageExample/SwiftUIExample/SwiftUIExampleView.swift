import DSWaveformImage
import SwiftUI

struct SwiftUIExampleView: View {
    private static let colors = [UIColor.red, UIColor.blue, UIColor.green]
    private static var randomColor: UIColor {
        colors[Int.random(in: 0..<colors.count)]
    }
    
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "wav")!

    @State var configuration: Waveform.Configuration = Waveform.Configuration(
        style: .filled(randomColor),
        position: .bottom
    )

    var body: some View {
        VStack {
            Text("This is a very basic SwiftUI usage example.\nSee `WaveformImageViewUI`.")
                .multilineTextAlignment(.center).padding()
            Button {
                configuration = configuration.with(style: .filled(Self.randomColor))
            } label: {
                Text("switch random color")
            }

            WaveformImageViewUI(audioURL: audioURL, configuration: configuration)
        }
        .padding(.top, 20)
    }
}

struct LiveRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIExampleView()
    }
}
