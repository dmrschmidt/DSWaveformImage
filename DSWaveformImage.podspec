Pod::Spec.new do |s|
  s.name         = "DSWaveformImage"
  s.version      = "2.0.0"
  s.summary      = "generate waveform images from audio files in iOS"
  s.description  = <<-DESC
                   DSWaveformImage and DSWaveformImageView generate waveform images of audio files.
                   DESC
  s.homepage     = "https://github.com/dmrschmidt/DSWaveformImage"
  s.screenshots  = "https://raw.github.com/dmrschmidt/DSWaveformImage/master/screenshot.png"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = "Dennis Schmidt"
  s.social_media_url   = "http://twitter.com/dmrschmidt"

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/dmrschmidt/DSWaveformImage.git", :tag => "#{s.version}" }
  s.source_files  = 'DSWaveformImage', 'DSWaveformImage/**/*.{h,m}'
  s.public_header_files = 'DSWaveformImage/**/*.h'
  s.frameworks  = 'AVFoundation'
  s.requires_arc = true
end
