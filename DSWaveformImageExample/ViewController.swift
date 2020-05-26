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
    @IBOutlet weak var bottomWaveformView: SpectralView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let waveformImageDrawer = WaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "sine-sweep-nonlog-mono", withExtension: "wav")!

        // always uses background thread rendering
        waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                          size: topWaveformView.bounds.size,
                                          style: .striped,
                                          position: .top) { image in
            // need to jump back to main queue
            DispatchQueue.main.async {
                self.topWaveformView.image = image
            }
        }

        middleWaveformView.waveformColor = UIColor.red
        middleWaveformView.waveformAudioURL = audioURL

        let waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
        waveformAnalyzer?.samples(count: Int(UIScreen.main.bounds.size.width) * Int(UIScreen.main.scale)) { samples, ffts in
            DispatchQueue.main.async {
                print("we got \(ffts?.count ?? 0) ffts")
                guard let remaining = ffts else { return }
                self.updateFFTView(fft: remaining.first!, remaining: Array(remaining.dropFirst()))
            }
        }
    }
    
    private func updateFFTView(fft: TempiFFT, remaining: [TempiFFT]) {
        self.bottomWaveformView.fft = fft
        self.bottomWaveformView.setNeedsDisplay()
        
        guard !remaining.isEmpty else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.updateFFTView(fft: remaining.first!, remaining: Array(remaining.dropFirst()))
        }
    }
}

