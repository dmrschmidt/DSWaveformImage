//
//  ViewController.swift
//  DSWaveformImageExample
//
//  Created by Dennis Schmidt on 06/02/2017.
//  Copyright © 2017 Dennis Schmidt. All rights reserved.
//

#if os(OSX)
    import AppKit
    import DSWaveformImageMac
    typealias ViewController = NSViewController
#elseif os(iOS)
    import UIKit
    import DSWaveformImage
    typealias ViewController = UIViewController
#endif


class SampleViewController: ViewController {
    
    @IBOutlet weak var topWaveformView: ImageView!
    @IBOutlet weak var middleWaveformView: WaveformImageView!
    @IBOutlet weak var bottomWaveformView: ImageView!
    @IBOutlet weak var lastWaveformView: ImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let waveformImageDrawer = WaveformImageDrawer()
        let audioURL = Bundle.main.url(forResource: "example_sound_2", withExtension: "m4a")!
        let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                 size: middleWaveformView.bounds.size,
                                                                 style: .striped,
                                                                 position: .bottom)

        topWaveformView.image = topWaveformImage



        middleWaveformView.waveformColor = Color.red
        middleWaveformView.waveformAudioURL = audioURL


        let bottomWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                                    size: middleWaveformView.bounds.size,
                                                                    color: Color.blue,
                                                                    style: .filled,
                                                                    paddingFactor: 5.0)

        bottomWaveformView.image = bottomWaveformImage



        let waveform = Waveform(audioAssetURL: audioURL)!
        let configuration = WaveformConfiguration(size: lastWaveformView.bounds.size,
                                                  color: Color.blue,
                                                  style: .striped,
                                                  position: .top)
        lastWaveformView.image = Image.from(waveform: waveform, configuration: configuration)


    }


}

