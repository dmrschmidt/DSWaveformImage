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
        style: .filled(randomColor),
        position: .bottom
    )

    @State var liveConfiguration: Waveform.Configuration = Waveform.Configuration(
        style: .striped(.init(color: randomColor, width: 3, spacing: 3)),
        position: .middle
    )

    var body: some View {
        VStack {
            Text("SwiftUI example")
                .font(.largeTitle.bold())

            Button {
                configuration = configuration.with(style: .filled(Self.randomColor))
                liveConfiguration = liveConfiguration.with(style: .striped(.init(color: Self.randomColor, width: 3, spacing: 3)))
            } label: {
                Label("switch color randomly", systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.body.bold())
            .padding()
            .background(Color(NSColor.systemGray).opacity(0.6))
            .cornerRadius(10)

            if #available(macOS 12.0, *) {
                WaveformView(audioURL: audioURL, configuration: configuration)
            } else {
                Text("at least macOS 12 is required")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
