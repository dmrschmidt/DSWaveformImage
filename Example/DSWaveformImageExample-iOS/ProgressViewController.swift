import Foundation
import UIKit
import SwiftUI
import DSWaveformImage

class ProgressViewController: UIViewController {
    @IBOutlet var waveformImageView: UIImageView!
    @IBOutlet var playbackWaveformImageView: UIImageView!

    private let waveformImageDrawer = WaveformImageDrawer()
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateWaveformImages()
    }

    @IBAction func shuffleProgressUIKit() {
        // In a real app, progress would come from your player.
        // Since there is various ways to play audio, eg AVPlayer,
        // the purpose of this example here is only to show how one
        // might visualize the progress, not how to calculate it.
        let progress = Double.random(in: 0...1)

        // Typically, this also does not need to be animated if your
        // progress updates come in at a high enough frequency
        // (every 0.1s for instance).
        updateProgressWaveform(progress)
    }

    @IBAction func openSwiftUIExample() {
        let hostingViewController = UIHostingController(rootView: ProgressExampleView())
        present(hostingViewController, animated: true)
    }

    private func updateProgressWaveform(_ progress: Double) {
        let fullRect = playbackWaveformImageView.bounds
        let newWidth = Double(fullRect.size.width) * progress

        let maskLayer = CAShapeLayer()
        let maskRect = CGRect(x: 0.0, y: 0.0, width: newWidth, height: Double(fullRect.size.height))

        let path = CGPath(rect: maskRect, transform: nil)
        maskLayer.path = path

        playbackWaveformImageView.layer.mask = maskLayer
    }

    private func updateWaveformImages() {
        Task {
            let image = try await waveformImageDrawer.waveformImage(fromAudioAt: audioURL, with: .init(size: playbackWaveformImageView.bounds.size, style: .filled(.darkGray)))

            DispatchQueue.main.async {
                self.waveformImageView.image = image
                self.playbackWaveformImageView.image = image.withTintColor(.red, renderingMode: .alwaysTemplate)
                self.shuffleProgressUIKit()
            }
        }
    }
}
