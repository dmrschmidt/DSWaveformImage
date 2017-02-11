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
                                                                 color: UIColor.black,
                                                                 style: .striped,
                                                                 position: .top,
                                                                 size: middleWaveformView.bounds.size,
                                                                 scale: UIScreen.main.scale)
        topWaveformView.image = topWaveformImage

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformStyle = .gradient
        middleWaveformView.waveformAudioURL = audioURL

        let bottomWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                 color: UIColor.blue,
                                                                 style: .filled,
                                                                 position: .middle,
                                                                 size: middleWaveformView.bounds.size,
                                                                 scale: UIScreen.main.scale)
        bottomWaveformView.image = bottomWaveformImage

        let waveform = Waveform(audioAssetURL: audioURL)!
        let configuration = WaveformConfiguration(color: UIColor.blue,
                                                  style: .striped,
                                                  position: .bottom,
                                                  size: lastWaveformView.bounds.size,
                                                  scale: UIScreen.main.scale)
        lastWaveformView.image = UIImage(waveform: waveform, configuration: configuration)
    }
}

