import DSWaveformImage
import SwiftUI

@available(iOS 15.0, *)
struct ProgressWaveformView: View {
    let audioURL: URL
    let progress: Double

    private let configuration = Waveform.Configuration(
        style: .striped(.init(color: .red, width: 3, spacing: 4)),
        damping: .init(percentage: 0.125, sides: .both)
    )

    @StateObject private var waveformDrawer = WaveformImageDrawer()
    @State private var waveformImage: UIImage = UIImage()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: waveformImage)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)

                Image(uiImage: waveformImage)
                    .resizable()
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: geometry.size.width * progress)
                    }
            }
                .onAppear {
                    guard waveformImage.size == .zero else { return }
                    update(size: geometry.size, url: audioURL, configuration: configuration)
                }
                .onChange(of: geometry.size) { update(size: $0, url: audioURL, configuration: configuration) }
                .onChange(of: audioURL) { update(size: geometry.size, url: $0, configuration: configuration) }
                .onChange(of: configuration) { update(size: geometry.size, url: audioURL, configuration: $0) }
        }
    }

    private func update(size: CGSize, url: URL, configuration: Waveform.Configuration) {
        Task(priority: .userInitiated) {
            let image = try! await waveformDrawer.waveformImage(fromAudioAt: url, with: configuration.with(size: size))
            await MainActor.run { waveformImage = image }
        }
    }
}

@available(iOS 15.0, *)
struct ProgressExampleView: View {
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
    @State private var progress: Double = .random(in: 0...1)

    var body: some View {
        VStack {
            ProgressWaveformView(audioURL: audioURL, progress: progress)

            Button(action: { progress = .random(in: 0...1) }) {
                Label("Progress", systemImage: "dice.fill")
            }.buttonStyle(.borderedProminent)
        }
        .background(Color(.systemYellow).ignoresSafeArea())
    }
}


@available(iOS 15.0, *)
struct ProgressExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressExampleView()
    }
}
