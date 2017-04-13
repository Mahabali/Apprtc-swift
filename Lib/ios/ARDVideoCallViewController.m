/*
 *  Copyright 2015 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDVideoCallViewController.h"

#import "ARDAppClient.h"
#import "ARDCaptureController.h"
#import "ARDSettingsModel.h"
#import "ARDVideoCallView.h"
#import "WebRTC/RTCAVFoundationVideoSource.h"
#import "WebRTC/RTCDispatcher.h"
#import "WebRTC/RTCLogging.h"
#import "WebRTC/RTCMediaConstraints.h"

@interface ARDVideoCallViewController () <ARDAppClientDelegate,
ARDVideoCallViewDelegate>
@property(nonatomic, strong) RTCVideoTrack *remoteVideoTrack;
@property(nonatomic, readonly) ARDVideoCallView *videoCallView;
@end

@implementation ARDVideoCallViewController {
    ARDAppClient *_client;
    RTCVideoTrack *_remoteVideoTrack;
    ARDCaptureController *_captureController;
    AVAudioSessionPortOverride _portOverride;
}

@synthesize videoCallView = _videoCallView;
@synthesize remoteVideoTrack = _remoteVideoTrack;
@synthesize delegate = _delegate;

- (instancetype)initForRoom:(NSString *)room
                 isLoopback:(BOOL)isLoopback
                isAudioOnly:(BOOL)isAudioOnly
          shouldMakeAecDump:(BOOL)shouldMakeAecDump
      shouldUseLevelControl:(BOOL)shouldUseLevelControl
                   delegate:(id<ARDVideoCallViewControllerDelegate>)delegate {
    if (self = [super init]) {
        ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
        _delegate = delegate;
        
        _client = [[ARDAppClient alloc] initWithDelegate:self];
        [_client connectToRoomWithId:room
                            settings:settingsModel
                          isLoopback:isLoopback
                         isAudioOnly:isAudioOnly
                   shouldMakeAecDump:shouldMakeAecDump
               shouldUseLevelControl:shouldUseLevelControl];
    }
    return self;
}

- (void)loadView {
    _videoCallView = [[ARDVideoCallView alloc] initWithFrame:CGRectZero];
    _videoCallView.delegate = self;
    _videoCallView.statusLabel.text =
    [self statusTextForState:RTCIceConnectionStateNew];
    self.view = _videoCallView;
}

#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client
   didChangeState:(ARDAppClientState)state {
    switch (state) {
            case kARDAppClientStateConnected:
            RTCLog(@"Client connected.");
            break;
            case kARDAppClientStateConnecting:
            RTCLog(@"Client connecting.");
            break;
            case kARDAppClientStateDisconnected:
            RTCLog(@"Client disconnected.");
            [self hangup];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client
didChangeConnectionState:(RTCIceConnectionState)state {
    RTCLog(@"ICE state changed: %ld", (long)state);
    __weak ARDVideoCallViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        ARDVideoCallViewController *strongSelf = weakSelf;
        strongSelf.videoCallView.statusLabel.text =
        [strongSelf statusTextForState:state];
    });
}

- (void)appClient:(ARDAppClient *)client
didCreateLocalCapturer:(RTCCameraVideoCapturer *)localCapturer {
    _videoCallView.localVideoView.captureSession = localCapturer.captureSession;
    ARDSettingsModel *settingsModel = [[ARDSettingsModel alloc] init];
    _captureController =
    [[ARDCaptureController alloc] initWithCapturer:localCapturer settings:settingsModel];
    [_captureController startCapture];
}

- (void)appClient:(ARDAppClient *)client
didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
}

- (void)appClient:(ARDAppClient *)client
didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    self.remoteVideoTrack = remoteVideoTrack;
    _videoCallView.statusLabel.hidden = YES;
}

- (void)appClient:(ARDAppClient *)client
      didGetStats:(NSArray *)stats {
    _videoCallView.statsView.stats = stats;
    [_videoCallView setNeedsLayout];
}

- (void)appClient:(ARDAppClient *)client
         didError:(NSError *)error {
    NSString *message =
    [NSString stringWithFormat:@"%@", error.localizedDescription];
    [self showAlertWithMessage:message];
    [self hangup];
}

#pragma mark - ARDVideoCallViewDelegate

- (void)videoCallViewDidHangup:(ARDVideoCallView *)view {
    [self hangup];
}

- (void)videoCallViewDidSwitchCamera:(ARDVideoCallView *)view {
    // TODO(tkchin): Rate limit this so you can't tap continously on it.
    // Probably through an animation.
    [_captureController switchCamera];
}

- (void)videoCallViewDidChangeRoute:(ARDVideoCallView *)view {
    AVAudioSessionPortOverride override = AVAudioSessionPortOverrideNone;
    if (_portOverride == AVAudioSessionPortOverrideNone) {
        override = AVAudioSessionPortOverrideSpeaker;
    }
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeAudioSession
                                 block:^{
                                     NSError *error = nil;
                                     AVAudioSession *session = [AVAudioSession sharedInstance];
                                     [session overrideOutputAudioPort:override error:&error];
                                     
                                     
                                     if ([session overrideOutputAudioPort:override error:&error]) {
                                         _portOverride = override;
                                     } else {
                                         RTCLogError(@"Error overriding output port: %@",
                                                     error.localizedDescription);
                                     }
                                     
                                 }];
}

- (void)videoCallViewDidEnableStats:(ARDVideoCallView *)view {
    _client.shouldGetStats = YES;
    _videoCallView.statsView.hidden = NO;
}

#pragma mark - Private

- (void)setRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    if (_remoteVideoTrack == remoteVideoTrack) {
        return;
    }
    [_remoteVideoTrack removeRenderer:_videoCallView.remoteVideoView];
    _remoteVideoTrack = nil;
    [_videoCallView.remoteVideoView renderFrame:nil];
    _remoteVideoTrack = remoteVideoTrack;
    [_remoteVideoTrack addRenderer:_videoCallView.remoteVideoView];
}

- (void)hangup {
    self.remoteVideoTrack = nil;
    _videoCallView.localVideoView.captureSession = nil;
    [_captureController stopCapture];
    _captureController = nil;
    [_client disconnect];
    [_delegate viewControllerDidFinish:self];
}

- (NSString *)statusTextForState:(RTCIceConnectionState)state {
    switch (state) {
            case RTCIceConnectionStateNew:
            case RTCIceConnectionStateChecking:
            return @"Connecting...";
            case RTCIceConnectionStateConnected:
            case RTCIceConnectionStateCompleted:
            case RTCIceConnectionStateFailed:
            case RTCIceConnectionStateDisconnected:
            case RTCIceConnectionStateClosed:
            case RTCIceConnectionStateCount:
            return nil;
    }
}

- (void)showAlertWithMessage:(NSString*)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:nil
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action){
                                                          }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}



@end
