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
    @IBOutlet weak var spectralView: SpectralView!
    @IBOutlet weak var middleWaveformView: WaveformImageView!
    @IBOutlet weak var bottomWaveformView: UIImageView!
    @IBOutlet weak var lastWaveformView: UIImageView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let waveformImageDrawer = WaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "10kHz", withExtension: "m4a")!
//        let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
//                                                                 size: middleWaveformView.bounds.size,
//                                                                 style: .striped,
//                                                                 position: .top)
//        topWaveformView.image = topWaveformImage

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformAudioURL = audioURL

        // uses background thread rendering
        let bounds = middleWaveformView.bounds
        DispatchQueue.global(qos: .userInitiated).async {
            let bottomWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                        size: bounds.size,
                                                                        color: UIColor.blue,
                                                                        backgroundColor: UIColor.lightGray,
                                                                        style: .filled,
                                                                        position: .custom(0.9),
                                                                        paddingFactor: 5.0)
            DispatchQueue.main.async {
                self.bottomWaveformView.image = bottomWaveformImage
            }
        }

        // uses background thread rendering
        let waveform = Waveform(audioAssetURL: audioURL)!
        let configuration = WaveformConfiguration(size: lastWaveformView.bounds.size,
                                                  color: UIColor.blue,
                                                  style: .bubbled,
                                                  position: .bottom)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let image = UIImage(waveform: waveform, configuration: configuration)
            DispatchQueue.main.async {
                self.lastWaveformView.image = image
            }
        }
        
        // FFT:
        let waveform2 = Waveform(audioAssetURL: audioURL)!
        let _ = waveform2.samples(count: 8192)
        let ffts = waveform2.audioProcessor.ffts
        print("ffts: \(ffts.count)")
        let fft = ffts[2]
        spectralView.fft = fft
        spectralView.setNeedsDisplay()
    }
}

