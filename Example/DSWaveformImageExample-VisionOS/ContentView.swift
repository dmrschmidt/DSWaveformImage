import SwiftUI
import DSWaveformImage
import DSWaveformImageViews

struct ContentView: View {
    private static let colors = [UIColor.systemPink, UIColor.systemBlue, UIColor.systemGreen]
    private static var randomColor: UIColor {
        colors[Int.random(in: 0..<colors.count)]
    }

    @State private var audioURL: URL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!

    @State var configuration: Waveform.Configuration = Waveform.Configuration(
        style: .gradient([.red, .green])
    )

    var body: some View {
        VStack {
            Text("SwiftUI example")
                .font(.largeTitle.bold())

            Button {
                configuration = configuration.with(style: .striped(.init(color: Self.randomColor)))
            } label: {
                Label("switch color randomly", systemImage: "arrow.triangle.2.circlepath")
            }
            .font(.body.bold())
            .padding()
            .background(Color(UIColor.systemGray).opacity(0.6))
            .cornerRadius(10)

            WaveformView(audioURL: audioURL, configuration: configuration, renderer: CircularWaveformRenderer())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
