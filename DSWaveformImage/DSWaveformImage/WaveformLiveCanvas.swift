import SwiftUI

@available(iOS 15.0, *)
public struct WaveformLiveCanvas: View {
    public static let defaultConfiguration = Waveform.Configuration(dampening: .init(percentage: 0.125, sides: .both))

    @Binding public var samples: [Float]
    @Binding public var configuration: Waveform.Configuration
    @Binding public var shouldDrawSilencePadding: Bool

    @StateObject private var waveformDrawer = WaveformImageDrawer()
    @State private var lastNewSampleCount: Int = 0

    public init(
        samples: Binding<[Float]>,
        configuration: Binding<Waveform.Configuration> = .constant(defaultConfiguration),
        shouldDrawSilencePadding: Binding<Bool> = .constant(false)
    ) {
        _samples = samples
        _configuration = configuration
        _shouldDrawSilencePadding = shouldDrawSilencePadding
        lastNewSampleCount = samples.count
    }

    public var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            context.withCGContext { cgContext in
                waveformDrawer.draw(waveform: samples, newSampleCount: lastNewSampleCount, on: cgContext, with: configuration.with(size: size))
            }
        }
        .onAppear {
            waveformDrawer.shouldDrawSilencePadding = shouldDrawSilencePadding
        }
        .onChange(of: samples) { [samples] newValue in
            lastNewSampleCount = max(0, newValue.count - samples.count)
        }
        .onChange(of: shouldDrawSilencePadding) { newValue in
            waveformDrawer.shouldDrawSilencePadding = newValue
        }
    }
}
