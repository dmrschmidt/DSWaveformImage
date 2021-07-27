//
//  SCAudioRecorder.h
//  soundcard
//
//  Created by Dennis Schmidt on 27.09.13.
//  Copyright (c) 2013 soundcard.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class SCAudioManager;

@protocol RecordingDelegate <NSObject>
- (void)audioManager:(SCAudioManager *)manager didAllowRecording:(BOOL)flag;
- (void)audioManager:(SCAudioManager *)manager didFinishRecordingSuccessfully:(BOOL)flag;
- (void)audioManager:(SCAudioManager *)manager didUpdateRecordProgress:(CGFloat)progress;
@end

@protocol PlaybackDelegate <NSObject>
- (void)audioManager:(SCAudioManager *)manager didFinishPlayingSuccessfully:(BOOL)flag;
- (void)audioManager:(SCAudioManager *)manager didUpdatePlayProgress:(CGFloat)progress;
@end

@interface SCAudioManager : NSObject <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
@property(nonatomic, weak) id<RecordingDelegate> recordingDelegate;
@property(nonatomic, weak) id<PlaybackDelegate> playbackDelegate;
@property(nonatomic) NSTimeInterval currentRecordingTime;

- (NSURL *)recordingsFolderURL;
- (NSURL *)recordedAudioFileURL;
- (NSURL *)downloadedAudioFileURL;

- (void)prepareAudioRecording;

- (BOOL)recording;
- (void)startRecording;
- (void)stopRecording;
- (BOOL)hasCapturedSufficientAudioLength;
- (void)setRecordingToBeSentAgainFromAudioAtURL:(NSURL *)audioURL;

- (float)lastAveragePower;

- (BOOL)playing;
- (void)playDownloadedAudio;
- (void)startPlayingRecordedAudio;
- (void)playAudioFileFromURL:(NSURL *)audioURL;
- (void)stopPlayingRecordedAudio;
- (void)reset;
@end
