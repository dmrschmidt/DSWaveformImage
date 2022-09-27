import SwiftUI

@available(iOS 15.0, *)
public struct WaveformLiveCanvas: View {
    public static let defaultConfiguration = Waveform.Configuration(dampening: .init(percentage: 0.125, sides: .both))

    public let samples: [Float]
    public let configuration: Waveform.Configuration
    public let shouldDrawSilencePadding: Bool

    @StateObject private var waveformDrawer = WaveformImageDrawer()

    public init(
        samples: [Float],
        configuration: Waveform.Configuration = defaultConfiguration,
        shouldDrawSilencePadding: Bool = false
    ) {
        self.samples = samples
        self.configuration = configuration
        self.shouldDrawSilencePadding = shouldDrawSilencePadding
    }

    public var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.withCGContext { cgContext in
                waveformDrawer.draw(waveform: samples, on: cgContext, with: configuration.with(size: size))
            }
        }
        .onAppear {
            waveformDrawer.shouldDrawSilencePadding = shouldDrawSilencePadding
        }
        .onChange(of: shouldDrawSilencePadding) { newValue in
            waveformDrawer.shouldDrawSilencePadding = newValue
        }
    }
}
