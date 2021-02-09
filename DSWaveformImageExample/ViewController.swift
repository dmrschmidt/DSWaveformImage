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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let waveformImageDrawer = WaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!

        // always uses background thread rendering
        waveformImageDrawer.waveformImage(
            fromAudioAt: audioURL,
            size: topWaveformView.bounds.size,
            style: .filled,
            position: .top
        ) { image in
            // need to jump back to main queue
            DispatchQueue.main.async {
                self.topWaveformView.image = image
            }
        }

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformAudioURL = audioURL

        let configuration = WaveformConfiguration(
            size: bottomWaveformView.bounds.size,
            color: UIColor.blue,
            style: .striped,
            position: .bottom,
            stripeWidth: 5,
            stripeSpacing: 2
        )

        waveformImageDrawer.waveformImage(fromAudioAt: audioURL, with: configuration) { image in
            DispatchQueue.main.async {
                self.bottomWaveformView.image = image
            }
        }

        // get access to the raw, normalized amplitude samples
        let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
        waveformAnalyzer?.samples(count: 10) { samples in
            print("sampled down to 10, results are \(samples ?? [])")
        }
    }
}
