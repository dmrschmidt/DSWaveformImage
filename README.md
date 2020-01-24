DSWaveformImage
===============

DSWaveformImage offers a few interfaces with the main purpose of drawing the
envelope waveform of audio files in iOS. To do so, you can use
`WaveformImageDrawer` or `WaveformImageView`.

Additionally, you can get a waveform's (normalized) samples directly as well by
creating an instance of `WaveformAnalyzer`.

More related iOS Controls
------------

You may also find the following iOS controls written in Swift interesting:

* [SwiftColorWheel](https://github.com/dmrschmidt/SwiftColorWheel) - a delightful color picker
* [QRCode](https://github.com/dmrschmidt/QRCode) - a customizable QR code generator

Installation
------------

* use carthage: `github "dmrschmidt/DSWaveformImage" ~> 6.1`
* use cocoapods: `pod 'DSWaveformImage', '~> 6.1'`
* manually: checkout the repo and build the DSWaveformImage.framework, then add to your project
* or simply add the DSWaveformImage folder directly into your project.

Usage
-----

Calculations are always performed and returned on a background thread, so make sure to return to the main thread before doing any UI work.

To create a `UIImage` using `WaveformImageDrawer`:

```swift
let waveformImageDrawer = WaveformImageDrawer()
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                  size: topWaveformView.bounds.size,
                                  style: .striped,
                                  position: .top) { image in
    // need to jump back to main queue
    DispatchQueue.main.async {
        self.topWaveformView.image = image
    }
}```

To create a `WaveformImageView` (`UIImageView` subclass):

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageView = WaveformImageView(frame: CGRect(x: 0, y: 0, width: 500, height: 300)
waveformImageView.waveformAudioURL = audioURL
```

And finally, to get an audio file's waveform samples:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
waveformAnalyzer.samples(count: 200) { samples in
    print("so many samples: \(samples)")
}
```

What it looks like
------------------

Waveforms can be rendered in 3 different styles: `.filled`, `.gradient` and
`.striped`. Similarly, there are 3 positions `.top`, `.middle` and `.bottom`
- relative to the canvas. The effect of each of those can be seen here:

<img src="https://github.com/dmrschmidt/DSWaveformImage/blob/master/screenshot.png" width="500" alt="Screenshot">

Migration
---------

`Waveform` and the `UIImage` category have been removed in 6.0.0 to simplify the API.
See `Usage` for current usage.

## See it live in action

SoundCard lets you send postcards with audio messages.

DSWaveformImage is used to draw the waveforms of the audio messages on postcards sent by [SoundCard](https://www.soundcard.io).

Check it out on the [App Store](http://bit.ly/soundcardio).

<img src="https://github.com/dmrschmidt/DSWaveformImage/blob/master/screenshot3.png" alt="Screenshot">
