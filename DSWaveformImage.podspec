Pod::Spec.new do |s|
  s.name         = "DSWaveformImage"
  s.version      = "1.0.0"
  s.summary      = "generate waveform images from audio files in iOS"

  s.description  = <<-DESC
                   DSWaveformImage and DSWaveformImageView generate waveform images of audio files.
                   DESC

  s.homepage     = "https://github.com/dmrschmidt/DSWaveformImage"
  # s.screenshots  = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = 'Dennis Schmidt'
  s.source       = { :git => "https://github.com/dmrschmidt/DSWaveformImage.git", :commit => "7f459e5c29bd132c8b332a04430c1b53eb46f640" }
  s.source_files  = 'DSWaveformImage', 'DSWaveformImage/**/*.{h,m}'
  s.public_header_files = 'DSWaveformImage/**/*.h'
  s.framework  = 'AVFoundation'
  s.requires_arc = true
end
