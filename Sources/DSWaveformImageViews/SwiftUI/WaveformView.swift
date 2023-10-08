import DSWaveformImage
import SwiftUI

@available(iOS 14.0, *)
/// Renders and displays a waveform for the audio at `audioURL`.
public struct WaveformView<Content: View>: View {
    private let audioURL: URL
    private let configuration: Waveform.Configuration
    private let renderer: WaveformRenderer
    private let priority: TaskPriority
    private let content: ((WaveformShape) -> Content)?

    @State private var samples: [Float] = []

    private let defaultStyler = DefaultShapeStyler()

    /**
     Creates a new WaveformView which displays a waveform for the audio at `audioURL`.

     - Parameters:
        - audioURL: The `URL` of the audio asset to be rendered.
        - configuration: The `Waveform.Configuration` to be used for rendering.
        - renderer: The `WaveformRenderer` implementation to be used. Defaults to `LinearWaveformRenderer`. Also comes with `CircularWaveformRenderer`.
        - priority: The `TaskPriority` used during analyzing. Defaults to `.userInitiated`.
        - content: ViewBuilder with the WaveformShape to be customized.
     */
    public init(
        audioURL: URL,
        configuration: Waveform.Configuration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both)),
        renderer: WaveformRenderer = LinearWaveformRenderer(),
        priority: TaskPriority = .userInitiated,
        @ViewBuilder content: @escaping (WaveformShape) -> Content
    ) {
        self.audioURL = audioURL
        self.configuration = configuration
        self.renderer = renderer
        self.priority = priority
        self.content = content
    }

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
           configuration: Waveform.Configuration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both)),
           renderer: WaveformRenderer = LinearWaveformRenderer(),
           priority: TaskPriority = .userInitiated
    ) where Content == _ConditionalContent<WaveformShape, EmptyView> {
        self.audioURL = audioURL
        self.configuration = configuration
        self.renderer = renderer
        self.priority = priority
        self.content = nil
    }

    public var body: some View {
        GeometryReader { geometry in
            Group {
                if let content = content {
                    content(WaveformShape(samples: samples, configuration: configuration, renderer: renderer))
                } else {
                    defaultStyler.style(
                        shape: WaveformShape(samples: samples, configuration: configuration, renderer: renderer),
                        with: configuration
                    )
                }
            }
                .onAppear {
                    guard samples.isEmpty else { return }
                    update(size: geometry.size, url: audioURL, configuration: configuration)
                }
                .onChange(of: geometry.size) { update(size: $0, url: audioURL, configuration: configuration) }
                .onChange(of: audioURL) { update(size: geometry.size, url: $0, configuration: configuration) }
                .onChange(of: configuration) { update(size: geometry.size, url: audioURL, configuration: $0) }
        }
    }

    private func update(size: CGSize, url: URL, configuration: Waveform.Configuration) {
        Task(priority: priority) {
            do {
                let samplesNeeded = Int(size.width * configuration.scale)
                let samples = try await WaveformAnalyzer().samples(fromAudioAt: url, count: samplesNeeded)
                await MainActor.run { self.samples = samples }
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}
