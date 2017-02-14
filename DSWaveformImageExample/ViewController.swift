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
    @IBOutlet weak var lastWaveformView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let waveformImageDrawer = WaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "example_sound_2", withExtension: "m4a")!
        let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                 size: middleWaveformView.bounds.size,
                                                                 style: .striped,
                                                                 position: .top)
        topWaveformView.image = topWaveformImage

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformAudioURL = audioURL

        let bottomWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                    size: middleWaveformView.bounds.size,
                                                                    color: UIColor.blue,
                                                                    style: .filled,
                                                                    paddingFactor: 5.0)
        bottomWaveformView.image = bottomWaveformImage

        let waveform = Waveform(audioAssetURL: audioURL)!
        let configuration = WaveformConfiguration(size: lastWaveformView.bounds.size,
                                                  color: UIColor.blue,
                                                  style: .striped,
                                                  position: .bottom)
        lastWaveformView.image = UIImage(waveform: waveform, configuration: configuration)
    }
}

