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
        let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "wav")!

        // always uses background thread rendering
        waveformImageDrawer.waveformImage(
            fromAudioAt: audioURL,
            size: topWaveformView.bounds.size,
            style: .gradient(
                [
                    UIColor(red: 255/255.0, green: 159/255.0, blue: 28/255.0, alpha: 1),
                    UIColor(red: 255/255.0, green: 191/255.0, blue: 105/255.0, alpha: 1),
                    UIColor.red
                ]
            ),
            position: .top,
            paddingFactor: 0.5
        ) { image in
            // need to jump back to main queue
            DispatchQueue.main.async {
                self.topWaveformView.image = image
            }
        }

        let middleColor = UIColor(red: 129/255.0, green: 178/255.0, blue: 154/255.0, alpha: 1)
        middleWaveformView.waveformStyle = .filled(middleColor)
        middleWaveformView.waveformAudioURL = audioURL

        let configuration = WaveformConfiguration(
            size: bottomWaveformView.bounds.size,
            style: .striped(UIColor(red: 51/255.0, green: 92/255.0, blue: 103/255.0, alpha: 1)),
            position: .bottom,
            paddingFactor: 0.5,
            stripeWidth: 5,
            stripeSpacing: 3
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
