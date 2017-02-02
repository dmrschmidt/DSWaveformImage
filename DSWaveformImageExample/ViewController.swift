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
    @IBOutlet weak var middleWaveformView: DSWaveformImageView!
    @IBOutlet weak var bottomWaveformView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let waveformImageDrawer = DSWaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
        let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                 color: UIColor.black,
                                                                 style: .filled,
                                                                 position: .top,
                                                                 size: middleWaveformView.bounds.size,
                                                                 scale: UIScreen.main.scale)
        topWaveformView.image = topWaveformImage

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformStyle = .gradient
        middleWaveformView.waveformAudioURL = audioURL

        let bottomWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                 color: UIColor.blue,
                                                                 style: .striped,
                                                                 position: .bottom,
                                                                 size: middleWaveformView.bounds.size,
                                                                 scale: UIScreen.main.scale)
        bottomWaveformView.image = bottomWaveformImage
    }
}

