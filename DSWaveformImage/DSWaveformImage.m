//
//  DSWaveformImage.m
//  soundcard
//
//  Created by Dennis Schmidt on 07.09.13.
//  Copyright (c) 2013 Dennis Schmidt. All rights reserved.
//

#import "DSWaveformImage.h"

#import <tgmath.h>

#define absX(x) (x<0?0-x:x)
#define minMaxX(x,mn,mx) (x<=mn?mn:(x>=mx?mx:x))
#define noiseFloor (-50.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude)/32767.0))

@implementation DSWaveformImage {
  DSWaveformStyle _style;
}

- (id)initWithStyle:(DSWaveformStyle)style {
  self = [super init];
  if (self) {
    _graphColor = [UIColor whiteColor];
    _style = style;
  }

  return self;
}

+ (UIImage *)waveformForAssetAtURL:(NSURL *)url
                             color:(UIColor *)color
                              size:(CGSize)size
                             scale:(CGFloat)scale
                             style:(DSWaveformStyle)style {
  AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
	if (!urlAsset) {
		return nil;
	}
	
  return [self waveformForAsset:urlAsset color:color size:size scale:scale style:style];
}

+ (UIImage *)waveformForAsset:(AVURLAsset *)asset
                        color:(UIColor *)color
                         size:(CGSize)size
                        scale:(CGFloat)scale
                        style:(DSWaveformStyle)style {
  DSWaveformImage *waveformImage = [[DSWaveformImage alloc] initWithStyle:style];
  waveformImage.graphColor = color;
  size.width *= scale;
  size.height *= scale;
	
  @try {
    NSData *imageData = [waveformImage renderPNGAudioPictogramLogForAssett:asset withSize:size];
		
    return [UIImage imageWithData:imageData scale:scale];
    
  } @catch (NSException *exception) {
    NSLog(@"DSWaveformImage: %@", exception);
    return nil;
  }
}

- (void)fillContext:(CGContextRef)context withRect:(CGRect)rect withColor:(UIColor *)color {
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextSetAlpha(context, 1.0);
  CGContextFillRect(context, rect);
}

- (void)fillBackgroundInContext:(CGContextRef)context withColor:(UIColor *)backgroundColor {
  CGSize imageSize = CGSizeMake(_imageWidth, _imageHeight);
  CGRect rect = CGRectZero;
  rect.size = imageSize;

  [self fillContext:context withRect:(CGRect) rect withColor:backgroundColor];
}

- (void)drawGraphWithStyle:(DSWaveformStyle)style
                    inRect:(CGRect)rect
                 onContext:(CGContextRef)context
                 withColor:(CGColorRef)graphColor {

  CGFloat graphCenter = rect.size.height / 2;
  CGFloat verticalPaddingDivisor = 1.2; // 2 = 50 % of height
  CGFloat sampleAdjustmentFactor = (rect.size.height / verticalPaddingDivisor) / 2;
  switch (style) {
    case DSWaveformStyleStripes:
      for (NSInteger intSample = 0; intSample < _sampleCount; intSample++) {
        Float32 sampleValue = (Float32) *_samples++;
        CGFloat pixels = (1.0 + sampleValue) * sampleAdjustmentFactor;
        CGFloat amplitudeUp = graphCenter - pixels;
        CGFloat amplitudeDown = graphCenter + pixels;

        if (intSample % 5 != 0) continue;
        CGContextMoveToPoint(context, intSample, amplitudeUp);
        CGContextAddLineToPoint(context, intSample, amplitudeDown);
        CGContextSetStrokeColorWithColor(context, graphColor);
        CGContextStrokePath(context);
      }
      break;

    case DSWaveformStyleFull:
      for (NSInteger pointX = 0; pointX < _sampleCount; pointX++) {
        Float32 sampleValue = (Float32) *_samples++;

        CGFloat pixels = ((1.0 + sampleValue) * sampleAdjustmentFactor);
        CGFloat amplitudeUp = graphCenter - pixels;
        CGFloat amplitudeDown = graphCenter + pixels;

        CGContextMoveToPoint(context, pointX, amplitudeUp);
        CGContextAddLineToPoint(context, pointX, amplitudeDown);
        CGContextSetStrokeColorWithColor(context, graphColor);
        CGContextStrokePath(context);
      }
      break;

    default:
      break;
  }
}

- (UIImage *)audioImageLogGraph:(Float32 *)samples
                   normalizeMax:(Float32)normalizeMax
                    sampleCount:(NSInteger)sampleCount
                     imageWidth:(CGFloat)imageWidth
                    imageHeight:(CGFloat)imageHeight {

  _samples = samples;
  _normalizeMax = normalizeMax;
  CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
  UIGraphicsBeginImageContext(imageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();

  _sampleCount = sampleCount;
  _imageHeight = imageHeight;
  _imageWidth = imageWidth;
  [self fillBackgroundInContext:context withColor:[UIColor clearColor]];

  CGColorRef graphColor = self.graphColor.CGColor;
  CGContextSetLineWidth(context, 1.0);
  CGRect graphRect = CGRectMake(0, 0, imageWidth, imageHeight);

  [self drawGraphWithStyle:self.style inRect:graphRect onContext:context withColor:graphColor];

  // Create new image
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

  // Tidy up
  UIGraphicsEndImageContext();

  return newImage;
}


- (NSData *)renderPNGAudioPictogramLogForAssett:(AVAsset *)songAsset withSize:(CGSize)size {
  NSError *error = nil;
  AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
  if ([songAsset.tracks count] == 0) return nil;
  AVAssetTrack *songTrack = [songAsset.tracks objectAtIndex:0];
  if (!songTrack) {
    return nil;
  }

  NSDictionary *outputSettingsDict = [[NSDictionary alloc] initWithObjectsAndKeys:
      [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
      [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
      [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
      [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
      [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
      nil];

  AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
  [reader addOutput:output];

  UInt32 sampleRate, channelCount;
  NSArray *formatDesc = songTrack.formatDescriptions;
  for (unsigned int i = 0; i < [formatDesc count]; ++i) {
    CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef) CFBridgingRetain([formatDesc objectAtIndex:i]);
    const AudioStreamBasicDescription *fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item);
    if (fmtDesc) {
      sampleRate = fmtDesc -> mSampleRate;
      channelCount = fmtDesc -> mChannelsPerFrame;
    }
  }

  _graphSize = size;
  NSInteger requiredNumberOfSamples = _graphSize.width;
  UInt32 bytesPerSample = 2 * channelCount;
  Float32 normalizeMax = fabs(noiseFloor);
  NSMutableData *fullSongData = [[NSMutableData alloc] initWithCapacity:requiredNumberOfSamples];
  [reader startReading];

  // first, read entire reader data (end of this while loop; copy all data over)
  NSMutableData *allData = [[NSMutableData alloc] initWithCapacity:requiredNumberOfSamples];
  while (reader.status == AVAssetReaderStatusReading) {
    AVAssetReaderTrackOutput *trackOutput = (AVAssetReaderTrackOutput *) [reader.outputs objectAtIndex:0];
    CMSampleBufferRef sampleBufferRef = [trackOutput copyNextSampleBuffer];

    if (sampleBufferRef) {
      CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBufferRef);

      size_t length = CMBlockBufferGetDataLength(blockBufferRef);
      NSMutableData *data = [NSMutableData dataWithLength:length];
      CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, data.mutableBytes);

      [allData appendData:data];

      CMSampleBufferInvalidate(sampleBufferRef);
      CFRelease(sampleBufferRef);
    }
  }

  NSData *finalData = nil;

  if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown) {
    // Something went wrong. Handle it.
  }

  if (reader.status == AVAssetReaderStatusCompleted) {
    NSUInteger sampleCount = allData.length / bytesPerSample;

    // FOR THE MOMENT WE ASSUME: sampleCount > requiredNumberOfSamples (SEE (a))
    // -> DOWNSAMPLE THE FINAL SAMPLES ARRAY
    // TODO: SUPPORT UPSAMPLING THE DATA
    Float32 samplesPerPixel = sampleCount / (Float32) requiredNumberOfSamples; // (a) always > 1

    // fill the samples with their values
    Float64 totalAmplitude = 0;
    SInt16 *samples = (SInt16 *) allData.mutableBytes;
    int j = 0;
    for (int i = 0; i < requiredNumberOfSamples; i++) {
      Float32 bucketLimit = (i + 1) * samplesPerPixel;
      while (j++ < bucketLimit) {
        Float32 amplitude = (Float32) *samples++;
        amplitude = decibel(amplitude);
        amplitude = minMaxX(amplitude, noiseFloor, 0);

        totalAmplitude += amplitude;
      }

      Float32 medianAmplitude = totalAmplitude / samplesPerPixel;
      if (fabsf(medianAmplitude) > fabsf(normalizeMax)) {
        normalizeMax = fabsf(medianAmplitude);
      }

      [fullSongData appendBytes:&medianAmplitude length:sizeof(medianAmplitude)];
      totalAmplitude = 0;
    }

    NSData *normalizedData = [self normalizeData:fullSongData normalizeMax:normalizeMax];

    UIImage *graphImage = [self audioImageLogGraph:(Float32 *) normalizedData.bytes
                                      normalizeMax:normalizeMax
                                       sampleCount:fullSongData.length / sizeof(Float32)
                                        imageWidth:requiredNumberOfSamples
                                       imageHeight:_graphSize.height];

    finalData = UIImagePNGRepresentation(graphImage);
  }

  return finalData;
}

- (NSData *)normalizeData:(NSData *)samples normalizeMax:(Float32)normalizeMax {
  NSMutableData *normalizedData = [[NSMutableData alloc] init];
  Float32 *rawData = (Float32 *) samples.bytes;

  for (int sampleIndex = 0; sampleIndex < _graphSize.width; sampleIndex++) {
    Float32 amplitude = (Float32) *rawData++;
    amplitude /= normalizeMax;
    [normalizedData appendBytes:&amplitude length:sizeof(amplitude)];
  }

  return normalizedData;
}

@end
