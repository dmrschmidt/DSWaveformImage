import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
public struct WaveformLiveCanvas: View {
    public static let defaultConfiguration = Waveform.Configuration(dampening: .init(percentage: 0.125, sides: .both))

    @Binding public var samples: [Float]
    @Binding public var configuration: Waveform.Configuration
    @Binding public var shouldDrawSilencePadding: Bool

    @StateObject private var waveformDrawer = WaveformImageDrawer()

    public init(
        samples: Binding<[Float]>,
        configuration: Binding<Waveform.Configuration> = .constant(defaultConfiguration),
        shouldDrawSilencePadding: Binding<Bool> = .constant(false)
    ) {
        _samples = samples
        _configuration = configuration
        _shouldDrawSilencePadding = shouldDrawSilencePadding
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
