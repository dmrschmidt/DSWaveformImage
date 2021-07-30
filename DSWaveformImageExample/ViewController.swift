//
//  ViewController.swift
//  DSWaveformImageExample
//
//  Created by Dennis Schmidt on 06/02/2017.
//  Copyright © 2017 Dennis Schmidt. All rights reserved.
//

import UIKit
import DSWaveformImage

class ViewController: UIViewController {
    @IBOutlet weak var topWaveformView: UIImageView!
    @IBOutlet weak var middleWaveformView: WaveformImageView!
    @IBOutlet weak var bottomWaveformView: UIImageView!

    private let waveformImageDrawer = WaveformImageDrawer()
    private let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "wav")!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateWaveformImages()

        // get access to the raw, normalized amplitude samples
        let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
        waveformAnalyzer?.samples(count: 10) { samples in
            print("sampled down to 10, results are \(samples ?? [])")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateWaveformImages()
    }

    private func updateWaveformImages() {
        // always uses background thread rendering
        waveformImageDrawer.waveformImage(
            fromAudioAt: audioURL, with: .init(
                size: topWaveformView.bounds.size,
                style: .gradient(
                    [
                        UIColor(red: 255/255.0, green: 159/255.0, blue: 28/255.0, alpha: 1),
                        UIColor(red: 255/255.0, green: 191/255.0, blue: 105/255.0, alpha: 1),
                        UIColor.red
                    ]
                ),
                dampening: .init(percentage: 0.2, sides: .right, easing: { x in pow(x, 4) }),
                position: .top,
                verticalScalingFactor: 2)
        ) { image in
            // need to jump back to main queue
            DispatchQueue.main.async {
                self.topWaveformView.image = image
            }
        }

        middleWaveformView.configuration = Waveform.Configuration(
            backgroundColor: .lightGray.withAlphaComponent(0.1),
            style: .striped(.init(color: UIColor(red: 51/255.0, green: 92/255.0, blue: 103/255.0, alpha: 1), width: 5, spacing: 5)),
            verticalScalingFactor: 0.5
        )
        middleWaveformView.waveformAudioURL = audioURL

        waveformImageDrawer.waveformImage(fromAudioAt: audioURL, with: bottomWaveformConfiguration) { image in
            DispatchQueue.main.async {
                self.bottomWaveformView.image = image
            }
        }
    }

    private var bottomWaveformConfiguration: Waveform.Configuration {
        Waveform.Configuration(
            size: bottomWaveformView.bounds.size,
            style: .filled(UIColor(red: 129/255.0, green: 178/255.0, blue: 154/255.0, alpha: 1)),
            position: .bottom
        )
    }
}
