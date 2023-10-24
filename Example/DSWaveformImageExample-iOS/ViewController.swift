//
//  ViewController.swift
//  DSWaveformImageExample
//
//  Created by Dennis Schmidt on 06/02/2017.
//  Copyright © 2017 Dennis Schmidt. All rights reserved.
//

import UIKit
import DSWaveformImage
import DSWaveformImageViews

class ViewController: UIViewController {
    @IBOutlet weak var topWaveformView: UIImageView!
    @IBOutlet weak var middleWaveformView: WaveformImageView!
    @IBOutlet weak var bottomWaveformView: UIImageView!

    private let waveformImageDrawer = WaveformImageDrawer()
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateWaveformImages()

        Task {
            // get access to the raw, normalized amplitude samples
            let waveformAnalyzer = WaveformAnalyzer()
            let samples = try await waveformAnalyzer.samples(fromAudioAt: audioURL, count: 10)
            print("sampled down to 10, results are \(samples)")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // you might want to call updateWaveformImages() here
        // to adapt to view changes
    }

    private func updateWaveformImages() {
        Task {
            // always uses background thread rendering
            let image = try await waveformImageDrawer.waveformImage(
                fromAudioAt: audioURL,
                with: .init(
                    size: topWaveformView.bounds.size,
                    style: .gradient(
                        [
                            UIColor(red: 255/255.0, green: 159/255.0, blue: 28/255.0, alpha: 1),
                            UIColor(red: 255/255.0, green: 191/255.0, blue: 105/255.0, alpha: 1),
                            UIColor.red
                        ]
                    ),
                    damping: .init(percentage: 0.2, sides: .right, easing: { x in pow(x, 4) }),
                    verticalScalingFactor: 2
                ),
                renderer: CircularWaveformRenderer()
            )

            // need to jump back to main queue
            await MainActor.run {
                self.topWaveformView.image = image
            }
        }

        middleWaveformView.configuration = Waveform.Configuration(
            backgroundColor: .lightGray.withAlphaComponent(0.1),
            style: .striped(.init(color: UIColor(red: 51/255.0, green: 92/255.0, blue: 103/255.0, alpha: 1), width: 5, spacing: 5)),
            verticalScalingFactor: 0.5
        )
        middleWaveformView.waveformAudioURL = audioURL

        Task {
            let image = try! await waveformImageDrawer.waveformImage(fromAudioAt: audioURL, with: bottomWaveformConfiguration)

            await MainActor.run {
                // as an added bonus, use CALayer's compositingFilter for more elaborate image display
                self.bottomWaveformView.layer.compositingFilter = "multiplyBlendMode"
                self.bottomWaveformView.image = image
            }
        }

        // Photo by Alexander Popov on Unsplash
        // https://unsplash.com/@5tep5?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText
        // https://unsplash.com/s/photos/techno?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText
    }

    private var bottomWaveformConfiguration: Waveform.Configuration {
        Waveform.Configuration(
            size: bottomWaveformView.bounds.size,
            style: .filled(UIColor(red: 129/255.0, green: 178/255.0, blue: 154/255.0, alpha: 1))
        )
    }
}
