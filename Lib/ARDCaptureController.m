/*
 *  Copyright 2017 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDCaptureController.h"

#import "ARDSettingsModel.h"

@implementation ARDCaptureController {
  RTCCameraVideoCapturer *_capturer;
  ARDSettingsModel *_settings;
  BOOL _usingFrontCamera;
}

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                        settings:(ARDSettingsModel *)settings {
  if ([super init]) {
    _capturer = capturer;
    _settings = settings;
    _usingFrontCamera = YES;
  }

  return self;
}

- (void)startCapture {
  AVCaptureDevicePosition position =
      _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
  AVCaptureDevice *device = [self findDeviceForPosition:position];
  AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];
  int fps = [self selectFpsForFormat:format];

  [_capturer startCaptureWithDevice:device format:format fps:fps];
}

- (void)stopCapture {
  [_capturer stopCapture];
}

- (void)switchCamera {
  _usingFrontCamera = !_usingFrontCamera;
  [self startCapture];
}

#pragma mark - Private

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
  NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
  for (AVCaptureDevice *device in captureDevices) {
    if (device.position == position) {
      return device;
    }
  }
  return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
  NSArray<AVCaptureDeviceFormat *> *formats =
      [RTCCameraVideoCapturer supportedFormatsForDevice:device];
  int targetWidth = [_settings currentVideoResolutionWidthFromStore];
  int targetHeight = [_settings currentVideoResolutionHeightFromStore];
  AVCaptureDeviceFormat *selectedFormat = nil;
  int currentDiff = INT_MAX;

  for (AVCaptureDeviceFormat *format in formats) {
    CMVideoDimensions dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
    int diff = abs(targetWidth - dimension.width) + abs(targetHeight - dimension.height);
    if (diff < currentDiff) {
      selectedFormat = format;
      currentDiff = diff;
    }
  }

  NSAssert(selectedFormat != nil, @"No suitable capture format found.");
  return selectedFormat;
}

- (int)selectFpsForFormat:(AVCaptureDeviceFormat *)format {
  Float64 maxFramerate = 0;
  for (AVFrameRateRange *fpsRange in format.videoSupportedFrameRateRanges) {
    maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate);
  }
  return maxFramerate;
}

@end
