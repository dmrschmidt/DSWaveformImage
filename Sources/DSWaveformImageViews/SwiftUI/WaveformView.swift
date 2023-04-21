import DSWaveformImage
import SwiftUI

@available(iOS 14.0, *)
/// Renders and displays a waveform for the audio at `audioURL`.
public struct WaveformView: View {
    public static let defaultConfiguration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both))

    private let audioURL: URL
    private let configuration: Waveform.Configuration
    private let renderer: WaveformRenderer
    private let priority: TaskPriority

    @StateObject private var waveformDrawer = WaveformImageDrawer()
    @State private var waveformImage: DSImage = DSImage()

    /**
     Creates a new WaveformView which displays a waveform for the audio at `audioURL`.

     - Parameters:
        - audioURL: The `URL` of the audio asset to be rendered.
        - configuration: The `Waveform.Configuration` to be used for rendering.
        - renderer: The `WaveformRenderer` implementation to be used. Defaults to `LinearWaveformRenderer`. Also comes with `CircularWaveformRenderer`.
        - priority: The `TaskPriority` used during analyzing. Defaults to `.userInitiated`.
     */
    public init(
        audioURL: URL,
        configuration: Waveform.Configuration = defaultConfiguration,
        renderer: WaveformRenderer = LinearWaveformRenderer(),
        priority: TaskPriority = .userInitiated
    ) {
        self.audioURL = audioURL
        self.configuration = configuration
        self.renderer = renderer
        self.priority = priority
    }

    public var body: some View {
        GeometryReader { geometry in
            image
                .onAppear {
                    guard waveformImage.size == .zero else { return }
                    update(size: geometry.size, url: audioURL, configuration: configuration)
                }
                .onChange(of: geometry.size) { update(size: $0, url: audioURL, configuration: configuration) }
                .onChange(of: audioURL) { update(size: geometry.size, url: $0, configuration: configuration) }
                .onChange(of: configuration) { update(size: geometry.size, url: audioURL, configuration: $0) }
        }
    }

    private var image: some View {
        #if os(macOS)
            Image(nsImage: waveformImage).resizable()
        #else
            Image(uiImage: waveformImage).resizable()
        #endif
    }

    private func update(size: CGSize, url: URL, configuration: Waveform.Configuration) {
        Task(priority: priority) {
            do {
                let image = try await waveformDrawer.waveformImage(fromAudioAt: url, with: configuration.with(size: size), renderer: renderer)
                await MainActor.run { waveformImage = image }
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
