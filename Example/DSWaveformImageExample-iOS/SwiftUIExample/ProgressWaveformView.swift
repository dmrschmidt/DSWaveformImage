import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct ProgressWaveformView: View {
    let audioURL: URL
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            WaveformView(audioURL: audioURL) { shape in
                shape.fill(.white)
                shape.fill(.red).mask(alignment: .leading) {
                    Rectangle().frame(width: geometry.size.width * progress)
                }
            }
        }
    }
}

struct ProgressExampleView: View {
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
    @State private var progress: Double = .random(in: 0...1)

    var body: some View {
        VStack {
            ProgressWaveformView(audioURL: audioURL, progress: progress)

            Button(action: { withAnimation { progress = .random(in: 0...1) }}) {
                Label("Progress", systemImage: "dice.fill")
            }.buttonStyle(.borderedProminent)
        }
        .background(Color(.systemYellow).ignoresSafeArea())
    }
}

struct ProgressExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressExampleView()
    }
}
