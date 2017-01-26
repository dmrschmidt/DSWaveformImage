//
//  DSWaveformImage.m
//  soundcard
//
//  Created by Dennis Schmidt on 07.09.13.
//  Copyright (c) 2013 Dennis Schmidt. All rights reserved.
//

#import "DSWaveformImageModel.h"

#define absX(x) (x < 0 ? 0 -x : x)
#define minMaxX(x, mn, mx) (x <= mn ? mn : (x >= mx ? mx : x))
#define noiseFloor (-50.0)
#define decibel(amplitude) (20.0 * log10(absX(amplitude) / 32767.0))

@implementation DSWaveformImage

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
                             style:(DSWaveformStyle)style
                          position:(DSWaveformPosition)position {
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    if (!urlAsset) {
        return nil;
    }

    return [self waveformForAsset:urlAsset color:color size:size scale:scale style:style position:position];
}

+ (UIImage *)waveformForAsset:(AVURLAsset *)asset
                        color:(UIColor *)color
                         size:(CGSize)size
                        scale:(CGFloat)scale
                        style:(DSWaveformStyle)style
                     position:(DSWaveformPosition)position {
    DSWaveformImage *waveformImage = [[DSWaveformImage alloc] initWithStyle:style];
    waveformImage.graphColor = color;
    size.width *= scale;
    size.height *= scale;

    @try {
        NSData *imageData = [waveformImage renderPNGAudioPictogramLogForAsset:asset withSize:size atPosition:position];
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

- (void)fillBackgroundInContext:(CGContextRef)context withSize:(CGSize)imageSize withColor:(UIColor *)backgroundColor {
    CGRect rect = CGRectZero;
    rect.size = imageSize;

    [self fillContext:context withRect:(CGRect) rect withColor:backgroundColor];
}

- (void)drawGraphFromSamples:(Float32 *)samples
                   withStyle:(DSWaveformStyle)style
                   withColor:(CGColorRef)graphColor
                      inRect:(CGRect)rect
                   onContext:(CGContextRef)context
                 sampleCount:(NSUInteger)sampleCount
                  atPosition:(DSWaveformPosition)waveformPosition{
    CGFloat graphCenter = rect.size.height / 2;
    CGFloat positionAdjustedGraphCenter = graphCenter - waveformPosition * graphCenter;
    CGFloat verticalPaddingDivisor = waveformPosition == DSWaveformPositionMiddle ? 1.2 : 1.0; // 2 = 50 % of height
    CGFloat sampleAdjustmentFactor = (rect.size.height / verticalPaddingDivisor) / 2;
    
    for (NSInteger intSample = 0; intSample < sampleCount; intSample++) {
        Float32 sampleValue = (Float32) *samples++;
        
        float pixels = (1.0 + sampleValue) * sampleAdjustmentFactor;
        float amplitudeUp = positionAdjustedGraphCenter - pixels;
        float amplitudeDown = positionAdjustedGraphCenter + pixels;
        
        if (style == DSWaveformStyleStripes && (intSample % 5 != 0)) continue;
        CGContextMoveToPoint(context, intSample, amplitudeUp);
        CGContextAddLineToPoint(context, intSample, amplitudeDown);
        CGContextSetStrokeColorWithColor(context, graphColor);
        CGContextStrokePath(context);
    }
}

- (UIImage *)audioImageLogGraph:(Float32 *)samples
                    sampleCount:(NSInteger)sampleCount
                     imageWidth:(CGFloat)imageWidth
                    imageHeight:(CGFloat)imageHeight
               waveformPosition:(DSWaveformPosition)waveformPosition {
    CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();

    [self fillBackgroundInContext:context withSize:imageSize withColor:[UIColor clearColor]];

    CGColorRef graphColor = self.graphColor.CGColor;
    CGContextSetLineWidth(context, 1.0);
    CGRect graphRect = CGRectMake(0, 0, imageWidth, imageHeight);

    [self drawGraphFromSamples:samples
                     withStyle:self.style
                     withColor:graphColor
                        inRect:graphRect
                     onContext:context
                   sampleCount:sampleCount
                    atPosition:waveformPosition];

    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    // Tidy up
    UIGraphicsEndImageContext();

    return newImage;
}


- (NSData *)renderPNGAudioPictogramLogForAsset:(AVAsset *)songAsset
                                      withSize:(CGSize)graphSize
                                    atPosition:(DSWaveformPosition)position {
    NSError *error = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
    if ([songAsset.tracks count] == 0) return nil;
    AVAssetTrack *songTrack = [songAsset.tracks objectAtIndex:0];
    if (!songTrack) {
        return nil;
    }

    NSDictionary *outputSettingsDict = @{
            AVFormatIDKey: @(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: @16,
            AVLinearPCMIsBigEndianKey: @NO,
            AVLinearPCMIsFloatKey: @NO,
            AVLinearPCMIsNonInterleaved: @NO
    };

    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc] initWithTrack:songTrack outputSettings:outputSettingsDict];
    [reader addOutput:output];

    UInt32 channelCount = 0;
    NSArray *formatDesc = songTrack.formatDescriptions;
    for (NSUInteger i = 0; i < [formatDesc count]; ++i) {
        CMAudioFormatDescriptionRef item = (CMAudioFormatDescriptionRef) CFBridgingRetain(formatDesc[i]);
        const AudioStreamBasicDescription *fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item);
        if (fmtDesc) {
            channelCount = fmtDesc->mChannelsPerFrame;
        }
    }

    NSUInteger requiredNumberOfSamples = (NSUInteger) graphSize.width;
    UInt32 bytesPerSample = 2 * channelCount;
    Float32 normalizeMax = (Float32) fabs(noiseFloor);
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
        NSInteger j = 0;
        for (NSInteger i = 0; i < requiredNumberOfSamples; i++) {
            Float32 bucketLimit = (i + 1) * samplesPerPixel;
            while (j++ < bucketLimit) {
                Float32 amplitude = (Float32) *samples++;
                amplitude = (Float32) decibel(amplitude);
                amplitude = (Float32) minMaxX(amplitude, noiseFloor, 0);

                totalAmplitude += amplitude;
            }

            Float32 medianAmplitude = (Float32) (totalAmplitude / samplesPerPixel);
            if (fabs(medianAmplitude) > fabs(normalizeMax)) {
                normalizeMax = (Float32) fabs(medianAmplitude);
            }

            [fullSongData appendBytes:&medianAmplitude length:sizeof(medianAmplitude)];
            totalAmplitude = 0;
        }

        NSData *normalizedData = [self normalizeData:fullSongData normalizeMax:normalizeMax graphSize:graphSize];

        UIImage *graphImage = [self audioImageLogGraph:(Float32 *) normalizedData.bytes
                                           sampleCount:fullSongData.length / sizeof(Float32)
                                            imageWidth:requiredNumberOfSamples
                                           imageHeight:graphSize.height
                                      waveformPosition:position];

        finalData = UIImagePNGRepresentation(graphImage);
    }

    return finalData;
}

- (NSData *)normalizeData:(NSData *)samples normalizeMax:(Float32)normalizeMax graphSize:(CGSize)graphSize {
    NSMutableData *normalizedData = [[NSMutableData alloc] init];
    Float32 *rawData = (Float32 *) samples.bytes;

    for (int sampleIndex = 0; sampleIndex < graphSize.width; sampleIndex++) {
        Float32 amplitude = (Float32) *rawData++;
        amplitude /= normalizeMax;
        [normalizedData appendBytes:&amplitude length:sizeof(amplitude)];
    }

    return normalizedData;
}

@end
