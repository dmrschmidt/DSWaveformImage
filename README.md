DSWaveformImage
===============

DSWaveformImage and DSWaveformImageView offer a simple drop-in solution to generate
and render waveform images from audio files in iOS.

Installation
------------

* use carthage: `github "dmrschmidt/DSWaveformImage" ~> 2.0.0`
* use cocoapods: `pod 'DSWaveformImage', '~> 2.0.0'`
* or add the DSWaveformImage folder directly into your project.

Usage
-----

To create a UIImage:

```objc
NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"example_sound" withExtension:@"m4a"];
UIImage *waveformImageTop = [DSWaveformImage waveformForAssetAtURL:audioURL
                                                         color:[UIColor redColor]
                                                          size:self.middleWaveformImageView.bounds.size
                                                         scale:[UIScreen mainScreen].scale
                                                         style:DSWaveformStyleFull
                                                      position:DSWaveformPositionTop];
```

To create a UIImageView:

```objc
NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"example_sound" withExtension:@"m4a"];
self.waveformImageView = [[DSWaveformImageView alloc] initWithFrame:CGRectMake(0, 0, 500, 300)];
[self.waveformImageView setAudioURL:audioURL];
```

What it looks like
------------------

![Screenshot](https://github.com/dmrschmidt/DSWaveformImage/blob/master/screenshot.png)
