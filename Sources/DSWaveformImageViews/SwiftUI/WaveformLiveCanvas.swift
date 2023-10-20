import SwiftUI
import DSWaveformImage

@available(iOS 15.0, macOS 12.0, *)
public struct WaveformLiveCanvas: View {
    public static let defaultConfiguration = Waveform.Configuration(damping: .init(percentage: 0.125, sides: .both))

    public let samples: [Float]
    public let configuration: Waveform.Configuration
    public let renderer: WaveformRenderer
    public let shouldDrawSilencePadding: Bool

    @StateObject private var waveformDrawer: WaveformImageDrawer

    public init(
        samples: [Float],
        configuration: Waveform.Configuration = defaultConfiguration,
        renderer: WaveformRenderer = LinearWaveformRenderer(),
        shouldDrawSilencePadding: Bool = false
    ) {
        let drawer = WaveformImageDrawer()
        self.samples = samples
        self.configuration = configuration
        self.renderer = renderer
        self.shouldDrawSilencePadding = shouldDrawSilencePadding

        drawer.shouldDrawSilencePadding = shouldDrawSilencePadding
        _waveformDrawer = StateObject(wrappedValue: drawer)
    }

    public var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.withCGContext { cgContext in
                waveformDrawer.draw(waveform: samples, on: cgContext, with: configuration.with(size: size), renderer: renderer)
            }
        }
        .onAppear {
            waveformDrawer.shouldDrawSilencePadding = shouldDrawSilencePadding
        }
        .modifier(OnChange(of: shouldDrawSilencePadding, action: { newValue in
            waveformDrawer.shouldDrawSilencePadding = newValue
        }))
    }
}

#if DEBUG
@available(iOS 15.0, macOS 12.0, *)
struct WaveformLiveCanvas_Previews: PreviewProvider {
    struct TestView: View {
        @State var show: Bool = false

        var body: some View {
            VStack {
                if show {
                    WaveformLiveCanvas(
                        samples: [],
                        configuration: liveConfiguration,
                        renderer: LinearWaveformRenderer(),
                        shouldDrawSilencePadding: show
                    )
                }
            }.onAppear() {
                show = true
            }
        }
    }

    static var liveConfiguration: Waveform.Configuration = Waveform.Configuration(
        style: .striped(.init(color: .systemPink, width: 3, spacing: 3))
    )

    static var previews: some View {
        TestView()
    }
}
#endif
