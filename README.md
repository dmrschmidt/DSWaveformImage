DSWaveformImage
===============

DSWaveformImage offers a few interfaces with the main purpose of drawing the
envelope waveform of audio files in iOS. To do so, you can use
`WaveformImageDrawer`, `WaveformImageView` or an extension on `UIImage`.

Additionally, you can get a waveform's (normalized) samples directly as well by
creating an instance of `Waveform`.

Installation
------------

* use carthage: `github "dmrschmidt/DSWaveformImage" ~> 5.0`
* use cocoapods: `pod 'DSWaveformImage', '~> 5.0'`
* or add the DSWaveformImage folder directly into your project.

Usage
-----

To create a `UIImage` using `WaveformImageDrawer`:

```swift
let waveformImageDrawer = WaveformImageDrawer()
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
let topWaveformImage = waveformImageDrawer.waveformImage(fromAudioAt: audioURL,
                                                         size: UIScreen.main.bounds.size,
                                                         color: UIColor.black,
                                                         backgroundColor: UIColor.black,
                                                         style: .filled,
                                                         position: .top,
                                                         scale: UIScreen.main.scale)
```


To create a `UIImage` using a `UIImage` extension:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
let waveform = Waveform(audioAssetURL: audioURL)!
let configuration = WaveformConfiguration(size: UIScreen.main.bounds.size,
                                          color: UIColor.blue,
                                          style: .striped,
                                          position: .middle,
                                          scale: UIScreen.main.scale,
                                          paddingFactor: 4.0)
let waveformImage = UIImage(waveform: waveform, configuration: configuration)
```

To create a `WaveformImageView` (`UIImageView` subclass):

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageView = WaveformImageView(frame: CGRect(x: 0, y: 0, width: 500, height: 300)
waveformImageView.waveformAudioURL = audioURL
```

And finally, to get an audio file's waveform samples:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
let waveform = Waveform(audioAssetURL: audioURL)!
print("so many samples: \(waveform.samples(count: 200))")
```


What it looks like
------------------

Waveforms can be rendered in 3 different styles: `.filled`, `.gradient` and
`.striped`. Similarly, there are 3 positions `.top`, `.middle` and `.bottom`
- relative to the canvas. The effect of each of those can be seen here:

![Screenshot](https://github.com/dmrschmidt/DSWaveformImage/blob/master/screenshot.png)
