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
        let audioURL = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        
        // always uses background thread rendering
        waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
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

        let waveform = Waveform(audioAssetURL: audioURL)!
        let configuration = WaveformConfiguration(size: bottomWaveformView.bounds.size,
                                                  color: UIColor.blue,
                                                  style: .filled,
                                                  position: .bottom)

        waveformImageDrawer.waveformImage(from: waveform, with: configuration) { [weak self] image in
           DispatchQueue.main.async {
               self?.bottomWaveformView.image = image
           }
        }
    }
}

