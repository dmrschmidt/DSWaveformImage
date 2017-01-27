//
//  DSViewController.m
//  DSWaveformImage
//
//  Created by Dennis Schmidt on 04.11.13.
//  Copyright (c) 2013 dmrschmidt. All rights reserved.
//

#import "DSViewController.h"
#import "DSWaveformImage.h"
#import "DSWaveformImageView.h"

@interface DSViewController ()
@property(weak, nonatomic) IBOutlet UIImageView *topImageView;
@property(weak, nonatomic) IBOutlet DSWaveformImageView *middleWaveformImageView;
@property(weak, nonatomic) IBOutlet UIImageView *bottomImageView;
@end

@implementation DSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"example_sound" withExtension:@"m4a"];

    UIImage *waveformImageTop = [DSWaveformImage waveformForAssetAtURL:audioURL
                                                                 color:[UIColor redColor]
                                                                  size:self.middleWaveformImageView.bounds.size
                                                                 scale:[UIScreen mainScreen].scale
                                                                 style:DSWaveformStyleFull
                                                              position:DSWaveformPositionTop];
    self.topImageView.image = waveformImageTop;

    [self.middleWaveformImageView setAudioURL:audioURL];

    UIImage *waveformImageBottom = [DSWaveformImage waveformForAssetAtURL:audioURL
                                                                    color:[UIColor greenColor]
                                                                     size:self.middleWaveformImageView.bounds.size
                                                                    scale:[UIScreen mainScreen].scale
                                                                    style:DSWaveformStyleFull
                                                                 position:DSWaveformPositionBottom];
    self.bottomImageView.image = waveformImageBottom;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
