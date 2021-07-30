//
//  SCAudioManager.m
//  soundcard
//
//  Created by Dennis Schmidt on 27.09.13.
//  Copyright (c) 2013 soundcard.io. All rights reserved.
//

#import "SCAudioManager.h"

@interface SCAudioManager ()
@property(nonatomic, strong) AVAudioRecorder *recorder;
@property(nonatomic, strong) AVAudioPlayer *player;
@property(nonatomic, strong) NSTimer *updateProgressIndicatorTimer;
@property(nonatomic, strong) NSString *currentRecordedAudioFilename;
@end

@implementation SCAudioManager

static const NSTimeInterval kMinRecordingTime =  0.3;
static const NSTimeInterval kMaxRecordingTime = 90.0;
static NSString const *kSCTemporaryRecordedAudioFilename = @"audio_temp.m4a";
static NSString const *kSCDownloadedAudioFilename = @"loaded_sound.m4a";
static NSString const *kSCRecordingsFolderName = @"recordings";

#pragma mark -
#pragma mark Public Interface
#pragma mark Helper methods

- (NSURL *)recordingsFolderURL {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *pathComponents = [NSArray arrayWithObjects:documentsDirectory, kSCRecordingsFolderName, nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

- (NSURL *)recordedAudioFileURL {
    NSArray *pathComponents = [NSArray arrayWithObjects:[[self recordingsFolderURL] path], self.currentRecordedAudioFilename, nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

- (NSURL *)downloadedAudioFileURL {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *pathComponents = [NSArray arrayWithObjects:documentsDirectory, kSCDownloadedAudioFilename, nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

#pragma mark Audio Recording methods

- (BOOL)recording {
    return self.recorder.isRecording;
}

- (void)startRecording {
    if (!self.recorder.isRecording) {
        // Stop the audio player before recording
        if (self.player.playing) {
            [self.player stop];
            [self.updateProgressIndicatorTimer invalidate];
        }

        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];

        // Start recording
        self.currentRecordingTime = 0.0;
        [self.recorder record];
        [self.updateProgressIndicatorTimer invalidate];
        self.updateProgressIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(recordingStatusDidUpdate) userInfo:nil repeats:YES];
    }
}

- (float)lastAveragePower {
    return [self.recorder averagePowerForChannel:0];
}

- (void)stopRecording {
    if (self.recorder.isRecording) {
        [self.recorder stop];

        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setActive:NO error:nil];

        [self.updateProgressIndicatorTimer invalidate];
    }
}

- (void)reset {
    [self.player stop];
    [self stopRecording];
    [self.recorder prepareToRecord];
    self.currentRecordingTime = 0.0;
}

- (void)setRecordingToBeSentAgainFromAudioAtURL:(NSURL *)audioURL {
    self.currentRecordingTime = kMinRecordingTime + 1; // just something to say we captured enough
    [self copyTemporaryAudioFileToPersistentLocation: audioURL];
    [self.recordingDelegate audioManager:self didFinishRecordingSuccessfully:YES];
}

#pragma mark -
#pragma mark Audio Recording / Playback Feedback methods

- (void)recordingStatusDidUpdate {
    self.currentRecordingTime = self.recorder.currentTime;
    CGFloat progress = fmax(0, fmin(1, self.currentRecordingTime / kMaxRecordingTime));

    [self.recorder updateMeters];
    [self.recordingDelegate audioManager:self didUpdateRecordProgress:progress];

    if(progress >= 1.0) {
        [self stopRecording];
    }
}

- (void)playbackStatusDidUpdate {
    CGFloat currentPlayTime = (CGFloat) self.player.currentTime / (CGFloat) self.player.duration;
    CGFloat progress = fmax(0, fmin(1, currentPlayTime));
    [self.playbackDelegate audioManager:self didUpdatePlayProgress:progress];
}

- (BOOL)hasCapturedSufficientAudioLength {
    return self.currentRecordingTime > kMinRecordingTime;
}

#pragma mark -
#pragma mark Audio Playback methods

- (void)playAudioFileFromURL:(NSURL *)audioURL {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
#pragma clang diagnostic pop

    if (!self.recorder.recording) {
        [self.updateProgressIndicatorTimer invalidate];
        self.updateProgressIndicatorTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(playbackStatusDidUpdate) userInfo:nil repeats:YES];

        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:nil];
        [self.player setDelegate:self];
        [self.player play];
    }
}

- (BOOL)playing {
    return self.player.playing;
}

- (void)startPlayingRecordedAudio {
    [self playAudioFileFromURL:self.recordedAudioFileURL];
}

- (void)stopPlayingRecordedAudio {
    if([self.player isPlaying]) {
        [self.player stop];
        [self.updateProgressIndicatorTimer invalidate];
        [self.playbackDelegate audioManager:self didFinishPlayingSuccessfully:NO];
    }
}

- (void)playDownloadedAudio {
    [self playAudioFileFromURL:self.downloadedAudioFileURL];
}

#pragma mark -
#pragma mark AVAudioRecorderDelegate methods

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag {
    [self.updateProgressIndicatorTimer invalidate];

    if([self hasCapturedSufficientAudioLength]) {
        [self copyTemporaryAudioFileToPersistentLocation:[self temporaryRecordedAudioFileURL]];
    }

    [self.recordingDelegate audioManager:self didFinishRecordingSuccessfully:flag];
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate methods

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self.updateProgressIndicatorTimer invalidate];

    [self.playbackDelegate audioManager:self didFinishPlayingSuccessfully:flag];
}

#pragma mark -
#pragma mark Private methods

- (NSURL *)temporaryRecordedAudioFileURL {
    NSString *homeDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *pathComponents = [NSArray arrayWithObjects:homeDirectory, kSCTemporaryRecordedAudioFilename, nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

- (void)prepareAudioRecording {
    // Set the temporary audio file
    NSURL *outputFileURL = [self temporaryRecordedAudioFileURL];

    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];

    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];

    // Initiate and prepare the recorder
    self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    self.recorder.delegate = self;
    self.recorder.meteringEnabled = YES;

    [session requestRecordPermission:^(BOOL granted) {
        [self.recordingDelegate audioManager:self didAllowRecording:granted];
        [self.recorder prepareToRecord];
    }];
}

- (void)copyTemporaryAudioFileToPersistentLocation:(NSURL *)audioURL {
    self.currentRecordedAudioFilename = [NSString stringWithFormat:@"%@.m4a", [[NSUUID UUID] UUIDString]];
    NSData *recordedAudioData = [NSData dataWithContentsOfURL:audioURL];

    [[NSFileManager defaultManager] createDirectoryAtPath:[[self recordingsFolderURL] path] withIntermediateDirectories:YES attributes:nil error:nil];
    [recordedAudioData writeToURL:[self recordedAudioFileURL] atomically:YES];
    NSLog(@"new audio file recorded to %@", [self recordedAudioFileURL]);
}

@end
