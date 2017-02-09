DSWaveformImage
===============

DSWaveformImageCreator and DSWaveformImageView offer a simple drop-in solution
to generate and render waveform images from audio files in iOS.

Installation
------------

* use carthage: `github "dmrschmidt/DSWaveformImage" ~> 3.1.0`
* use cocoapods: `pod 'DSWaveformImage', '~> 3.1.0'`
* or add the DSWaveformImage folder directly into your project.

Usage
-----

To create a `UIImage` using `DSWaveformImageDrawer`:

```swift
let waveformImageDrawer = DSWaveformImageDrawer()
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                         color: UIColor.black,
                                                         style: .filled,
                                                         position: .top,
                                                         size: middleWaveformView.bounds.size,
                                                         scale: UIScreen.main.scale)
```

To create a `DSWaveformImageView` (`UIImageView` subclass):

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageView = DSWaveformImageView(frame: CGRect(x: 0, y: 0, width: 500, height: 300)
waveformImageView.waveformAudioURL = audioURL
```

What it looks like
------------------

Waveforms can be rendered in 3 different styles: `.filled`, `.gradient` and
`.striped`. Similarly, there are 3 positions `.top`, `.middle` and `.bottom`
- relative to the canvas. The effect of each of those can be seen here:

![Screenshot](https://github.com/dmrschmidt/DSWaveformImage/blob/master/screenshot.png)
