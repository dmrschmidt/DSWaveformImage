import SwiftUI
import DSWaveformImage
import DSWaveformImageViews

@available(iOS 15.0, *)
struct RecordingIndicatorView: View {
    let samples: [Float]
    let duration: TimeInterval

    @Binding var isRecording: Bool

    @State var configuration: Waveform.Configuration = .init(
        style: .striped(.init(color: .systemGray, width: 3, spacing: 3)),
        damping: .init()
    )

    static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    var body: some View {
        HStack {
            WaveformLiveCanvas(samples: samples, configuration: configuration)
                .padding(.vertical, 2)

            Text(Self.timeFormatter.string(from: duration) ?? "00:00")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundColor(Color(.systemGray))

            Button(action: { isRecording.toggle() }) {
                Image(systemName: isRecording ? "stop.circle" : "record.circle")
                    .resizable()
                    .scaledToFit()
            }
            .padding(.vertical, 4)
            .padding(.trailing)
            .foregroundColor(Color(.systemRed))
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .frame(height: 32)
    }
}

#if DEBUG
    @available(iOS 15.0, *)
    struct RecordingIndicatorView_Previews: PreviewProvider {
        static var previews: some View {
            RecordingIndicatorView(samples: [], duration: 120, isRecording: .constant(true))
        }
    }
#endif
