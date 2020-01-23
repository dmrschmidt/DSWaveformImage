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
    
    private var waveformAnalyzer: WaveformAnalyzer!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let waveformImageDrawer = WaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
        waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)

        // always uses background thread rendering
        waveformImageDrawer.waveformImage(from: waveformAnalyzer,
                                          size: topWaveformView.bounds.size,
                                          style: .striped,
                                          position: .top) { [weak self] image in
                                            // need to jump back to main queue
                                            DispatchQueue.main.async {
                                                self?.topWaveformView.image = image
                                            }
        }

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformAudioURL = audioURL

        waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
        let configuration = WaveformConfiguration(size: bottomWaveformView.bounds.size,
                                                  color: UIColor.blue,
                                                  style: .filled,
                                                  position: .bottom)

        waveformImageDrawer.waveformImage(from: waveformAnalyzer, with: configuration) { [weak self] image in
           DispatchQueue.main.async {
               self?.bottomWaveformView.image = image
           }
        }
    }
}

