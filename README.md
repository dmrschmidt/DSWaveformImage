DSWaveformImage - iOS & macOS realtime audio waveform rendering
===============
[![Swift Package Manager compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)

DSWaveformImage offers a native interfaces for drawing the envelope waveform of audio data 
in **iOS**, **iPadOS**, **macOS** or via Catalyst. To do so, you can use

* [`WaveformImageView`](Sources/DSWaveformImageViews/UIKit/WaveformImageView.swift) (UIKit) / [`WaveformView`](Sources/DSWaveformImageViews/SwiftUI/WaveformView.swift) (SwiftUI) to render a static waveform from an audio file or 
* [`WaveformLiveView`](Sources/DSWaveformImageViews/UIKit/WaveformLiveView.swift) (UIKit) / [`WaveformLiveCanvas`](Sources/DSWaveformImageViews/SwiftUI/WaveformLiveCanvas.swift) (SwiftUI) to realtime render a waveform of live audio data (e.g. from `AVAudioRecorder`)
* `WaveformImageDrawer` to generate a waveform `UIImage` from an audio file

Additionally, you can get a waveform's (normalized) `[Float]` samples directly as well by
creating an instance of `WaveformAnalyzer`.

Example UI (included in repository)
------------

For a practical real-world example usage of a SwiftUI live audio recording waveform rendering, see [RecordingIndicatorView](Example/DSWaveformImageExample-iOS/SwiftUIExample/SwiftUIExampleView.swift).


<img src="./Promotion/recorder-example.png" alt="Audio Recorder Example" width="358">

More related iOS Controls
------------

You may also find the following iOS controls written in Swift interesting:

* [SwiftColorWheel](https://github.com/dmrschmidt/SwiftColorWheel) - a delightful color picker
* [QRCode](https://github.com/dmrschmidt/QRCode) - a customizable QR code generator

If you really like this library (aka Sponsoring)
------------
I'm doing all this for fun and joy and because I strongly believe in the power of open source. On the off-chance though, that using my library has brought joy to you and you just feel like saying "thank you", I would smile like a 4-year old getting a huge ice cream cone, if you'd support my via one of the sponsoring buttons ☺️💕

If you're feeling in the mood of sending someone else a lovely gesture of appreciation, maybe check out my iOS app [💌 SoundCard](https://www.soundcard.io) to send them a real postcard with a personal audio message.

<a href="https://www.buymeacoffee.com/dmrschmidt" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>

Installation
------------

* use SPM: add `https://github.com/dmrschmidt/DSWaveformImage` and set "Up to Next Major" with "11.0.0"

```swift
import DSWaveformImage // for core classes to generate `UIImage` / `NSImage` directly
import DSWaveformImageViews // if you want to use the native UIKit / SwiftUI views
```

**Deprecated or discouraged** but still possible alternative ways for older apps:

* since it has no other dependencies you may simply copy the `Sources` folder directly into your project
* use carthage: `github "dmrschmidt/DSWaveformImage" ~> 7.0` (last supported version is 10)
* or, sunset since 6.1.1: ~~use cocoapods: `pod 'DSWaveformImage', '~> 6.1'`~~

Usage
-----

`DSWaveformImage` provides 3 kinds of tools to use
* native SwiftUI views - [SwiftUI example usage code](Example/DSWaveformImageExample-iOS/SwiftUIExample/SwiftUIExampleView.swift)
* native UIKit views - [UIKit example usage code](Example/DSWaveformImageExample-iOS/ViewController.swift)
* access to the raw renderes and processors

The core renderes and processors as well as SwiftUI views natively support iOS & macOS, using `UIImage` & `NSImage` respectively.

### SwiftUI

#### `WaveformView` - renders a one-off waveform from an audio file:

```swift
@State var audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
WaveformView(audioURL: audioURL)
```

#### `WaveformLiveCanvas` - renders a live waveform from `(0...1)` normalized samples:

```swift
@StateObject private var audioRecorder: AudioRecorder = AudioRecorder() // just an example
WaveformLiveCanvas(samples: audioRecorder.samples)
```

### UIKit

#### `WaveformImageView` - renders a one-off waveform from an audio file:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageView = WaveformImageView(frame: CGRect(x: 0, y: 0, width: 500, height: 300)
waveformImageView.waveformAudioURL = audioURL
```

#### `WaveformLiveView` - renders a live waveform from `(0...1)` normalized samples:

Find a full example in the [sample project's RecordingViewController](Example/DSWaveformImageExample-iOS/RecordingViewController.swift).

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

### Raw API

#### Configuration

*Note:* Calculations are always performed and returned on a background thread, so make sure to return to the main thread before doing any UI work.

Check `Waveform.Configuration` in [WaveformImageTypes](./Sources/DSWaveformImage/WaveformImageTypes.swift) for various configuration options.

#### `WaveformImageDrawer` - creates a `UIImage` waveform from an audio file:

```swift
let waveformImageDrawer = WaveformImageDrawer()
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformImageDrawer.waveformImage(fromAudioAt: audioURL, with: .init(
                                  size: topWaveformView.bounds.size,
                                  style: .filled(UIColor.black)),
                                  renderer: LinearWaveformRenderer()) { image in
    // need to jump back to main queue
    DispatchQueue.main.async {
        self.topWaveformView.image = image
    }
}
```

#### `WaveformAnalyzer` - calculates an audio file's waveform sample:

```swift
let audioURL = Bundle.main.url(forResource: "example_sound", withExtension: "m4a")!
waveformAnalyzer = WaveformAnalyzer(audioAssetURL: audioURL)
waveformAnalyzer.samples(count: 200) { samples in
    print("so many samples: \(samples)")
}
```

### `async` / `await` Support

The public API has been updated in 9.1 to support `async` / `await`. See the example app for an illustration.

```swift
public class WaveformAnalyzer {
    func samples(count: Int, qos: DispatchQoS.QoSClass = .userInitiated) async throws -> [Float]
}

public class WaveformImageDrawer {
    public func waveformImage(
        fromAudioAt audioAssetURL: URL,
        with configuration: Waveform.Configuration,
        qos: DispatchQoS.QoSClass = .userInitiated
    ) async throws -> UIImage
}
```


### Playback Progress Indication

If you're playing back audio files and would like to indicate the playback progress to your users, you can [find inspiration in this ticket](https://github.com/dmrschmidt/DSWaveformImage/issues/21). There's various other ways of course, depending on your use case and design. One way to achieve this in SwiftUI could be


```swift
// @State var progress: CGFloat = 0 // must be between 0 and 1

ZStack(alignment: .leading) {
    WaveformView(audioURL: audioURL, configuration: configuration)
    WaveformView(audioURL: audioURL, configuration: configuration.with(style: .filled(.red)))
        .mask(alignment: .leading) {
            GeometryReader { geometry in
                Rectangle().frame(width: geometry.size.width * progress)
            }
        }
}
```

This will result in something like the image below. 

<div align="center">
  <img src="./Promotion/progress-example.png" height="200" alt="playback progress waveform">
</div>

Keep in mind though, that this approach will calculate and render the waveform twice initially. This will be more than fine for 95% of typical use cases. If you do have very strict performance requirements however, you may want to use `WaveformImageDrawer` directly instead of the build-in views. There is currently no plan to integrate this as a 1st class citizen as every app will have different requirements, and `WaveformImageDrawer` as well as `WaveformAnalyzer` are as simple to use as the views themselves.

### Loading remote audio files from URL

For one example way to display waveforms for audio files on remote URLs see https://github.com/dmrschmidt/DSWaveformImage/issues/22.

What it looks like
------------------

Waveforms can be rendered in 2 different ways and 5 different styles each.

By default [`LinearWaveformRenderer`](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Sources/DSWaveformImage/Renderers/LinearWaveformRenderer.swift) is used, which draws a linear 2D amplitude envelope.

[`CircularWaveformRenderer`](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Sources/DSWaveformImage/Renderers/CircularWaveformRenderer.swift) is available as an alternative, which can be passed in to the `WaveformView` or `WaveformLiveView` respectively. It draws a circular
2D amplitude envelope.

You can implement your own renderer by implementing [`WaveformRenderer`](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Sources/DSWaveformImage/Renderers/WaveformRenderer.swift).
 
The following styles can be applied to either renderer:
 - **filled**: Use solid color for the waveform.
 - **outlined**: Draws the envelope as an outline with the provided thickness.
 - **gradient**: Use gradient based on color for the waveform.
 - **gradientOutlined**: Use gradient based on color for the waveform. Draws the envelope as an outline with the provided thickness.
 - **striped**: Use striped filling based on color for the waveform.

<div align="center">
  <img src="./Promotion/screenshot.png" width="500" alt="Screenshot">
</div>


### Live waveform rendering
https://user-images.githubusercontent.com/69365/127739821-061a4345-0adc-4cc1-bfd6-f7cfbe1268c9.mov


Migration
---------
In 12.0.0
* The rendering pipeline was split out from the analysis. You can now create your own renderes by subclassing [`WaveformRenderer`](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Sources/DSWaveformImage/Renderers/WaveformRenderer.swift).
* A new [`CircularWaveformRenderer`](https://github.com/dmrschmidt/DSWaveformImage/blob/main/Sources/DSWaveformImage/Renderers/CircularWaveformRenderer.swift) has been added.
* `position` was removed from `Waveform.Configuration`, see [0447737](https://github.com/dmrschmidt/DSWaveformImage/commit/044773782092becec0424527f6feef061988db7a).
* new `Waveform.Style` option have been added and need to be accounted for in `switch` statements etc.

In 11.0.0 the library was split into two: `DSWaveformImage` and `DSWaveformImageViews`. If you've used any of the native views bevore, just add the additional `import DSWaveformImageViews`.
The SwiftUI views have changed from taking a Binding to the respective plain values instead.

In 9.0.0 a few public API's have been slightly changed to be more concise. All types have also been grouped under the `Waveform` enum-namespace. Meaning `WaveformConfiguration` for instance has become `Waveform.Configuration` and so on.

In 7.0.0 colors have moved into associated values on the respective `style` enum.

`Waveform` and the `UIImage` category have been removed in 6.0.0 to simplify the API.
See `Usage` for current usage.

## See it live in action

[SoundCard - postcards with sound](https://www.soundcard.io) lets you send real, physical postcards with audio messages. Right from your iOS device.

DSWaveformImage is used to draw the waveforms of the audio messages that get printed on the postcards sent by [SoundCard - postcards with audio](https://www.soundcard.io).

&nbsp;

<div align="center">
    <a href="http://bit.ly/soundcardio">
        <img src="./Promotion/appstore.svg" alt="Download SoundCard">
        
Download SoundCard on the App Store.
    </a>
</div>

&nbsp;

<a href="http://bit.ly/soundcardio">
<img src="https://www.soundcard.io/images/opengraph-preview.jpg" alt="Screenshot">
</a>
