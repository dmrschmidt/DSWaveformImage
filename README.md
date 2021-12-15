DSWaveformImage - Realtime audio waveform rendering
===============
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)


DSWaveformImage offers a few interfaces for the purpose of drawing the
envelope waveform of audio data in iOS. To do so, you can use

* `WaveformImageDrawer` to generate a waveform `UIImage` from an audio file
* `WaveformImageView` to render a static waveform from an audio file or 
* `WaveformLiveView` to realtime render a waveform of live audio data (e.g. from `AVAudioRecorder`)

Additionally, you can get a waveform's (normalized) `[Float]` samples directly as well by
creating an instance of `WaveformAnalyzer`.

More related iOS Controls
------------

You may also find the following iOS controls written in Swift interesting:

* [SwiftColorWheel](https://github.com/dmrschmidt/SwiftColorWheel) - a delightful color picker
* [QRCode](https://github.com/dmrschmidt/QRCode) - a customizable QR code generator

Installation
------------

* use SPM: add `https://github.com/dmrschmidt/DSWaveformImage` and set "Up to Next Major" with "9.0.0"

**Deprecated or discouraged** but still possible alternative ways for older apps:

* since it has no other dependencies you may simply copy the `DSWaveformImage` folder directly into your project
* use carthage: `github "dmrschmidt/DSWaveformImage" ~> 7.0`
* or, sunset since 6.1.1: ~~use cocoapods: `pod 'DSWaveformImage', '~> 6.1'`~~

Usage
-----

### SwiftUI Support

All DSWaveformImage views, while native UIKit, can be used from within SwiftUI easily by wrapping them as [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable).

[Check out WaveformImageViewUI](./DSWaveformImageExample/SwiftUIExample/WaveformImageViewUI.swift) in the example app for a copy & paste ready starting point.

A more full-featured out of the box SwiftUI support will be coming eventually. Until then it should be straightforward to use via `UIViewRepresentable`.


### Configuration

*Note:* Calculations are always performed and returned on a background thread, so make sure to return to the main thread before doing any UI work.

Check `Waveform.Configuration` in [WaveformImageTypes](./DSWaveformImage/DSWaveformImage/WaveformImageTypes.swift) for various configuration options.

### `WaveformImageDrawer` - creates a `UIImage` waveform from an audio file:

```swift
let waveformImageDrawer = WaveformImageDrawer()
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageDrawer.waveformImage(fromAudioAt: audioURL, with: .init(
                                  size: topWaveformView.bounds.size,
                                  style: .filled(UIColor.black),
                                  position: .top) { image in
    // need to jump back to main queue
    DispatchQueue.main.async {
        self.topWaveformView.image = image
    }
}
```

### `WaveformImageView` - renders a one-off waveform from an audio file:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageView = WaveformImageView(frame: CGRect(x: 0, y: 0, width: 500, height: 300)
waveformImageView.waveformAudioURL = audioURL
```

### `WaveformLiveView` - renders a live waveform from `(0...1)` normalized samples:

Find a full example in the [sample project's RecordingViewController](https://github.com/dmrschmidt/DSWaveformImage/blob/main/DSWaveformImageExample/RecordingViewController.swift).

```swift
let waveformView = WaveformLiveView()

// configure and start AVAudioRecorder
let recorder = AVAudioRecorder()
recorder.isMeteringEnabled = true // required to get current power levels

// after all the other recording (omitted for focus) setup, periodically (every 20ms or so):
recorder.updateMeters() // gets the current value
let currentAmplitude = 1 - pow(10, recorder.averagePower(forChannel: 0) / 20)
waveformView.add(sample: currentAmplitude)
```

### `WaveformAnalyzer` - calculates an audio file's waveform sample:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
waveformAnalyzer.samples(count: 200) { samples in
    print("so many samples: \(samples)")
}
```

### Playback Indication

If you're playing back audio files and would like to indicate the playback progress to your users, you can [find inspiration in this ticket](https://github.com/dmrschmidt/DSWaveformImage/issues/21).
There's various other ways of course, depending on your use case and design. Using `WaveformLiveView` may be another one in conjunction with `AVAudioPlayer` (note that `AVPlayer` does *not* offer
the same simple access to its audio metering data, so is not as suitable out of the box).

### Loading remote audio files from URL

For one example way to display waveforms for audio files on remote URLs see https://github.com/dmrschmidt/DSWaveformImage/issues/22.

What it looks like
------------------

Waveforms can be rendered in 3 different styles: `.filled`, `.gradient` and
`.striped`. 

Similarly, there are 3 positions relative to the canvas, `.top`, `.middle` and `.bottom`.

The effect of each of those can be seen here:

<img src="https://github.com/dmrschmidt/DSWaveformImage/blob/main/screenshot.png" width="500" alt="Screenshot">


### Live waveform rendering
https://user-images.githubusercontent.com/69365/127739821-061a4345-0adc-4cc1-bfd6-f7cfbe1268c9.mov


Migration
---------
In 9.0.0 a few public API's have been slightly changed to be more concise. All types have also been grouped under the `Waveform` enum-namespace. Meaning `WaveformConfiguration` for instance has become `Waveform.Configuration` and so on.

In 7.0.0 colors have moved into associated values on the respective `style` enum.

`Waveform` and the `UIImage` category have been removed in 6.0.0 to simplify the API.
See `Usage` for current usage.

## See it live in action

SoundCard lets you send postcards with audio messages.

DSWaveformImage is used to draw the waveforms of the audio messages on postcards sent by [SoundCard](https://www.soundcard.io).

Check it out on the [App Store](http://bit.ly/soundcardio).

<img src="https://github.com/dmrschmidt/DSWaveformImage/blob/main/screenshot3.png" alt="Screenshot">
