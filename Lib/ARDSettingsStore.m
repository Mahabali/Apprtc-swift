/*
 *  Copyright 2016 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDSettingsStore.h"

static NSString *const kVideoResolutionKey = @"rtc_video_resolution_key";
static NSString *const kVideoCodecKey = @"rtc_video_codec_key";
static NSString *const kBitrateKey = @"rtc_max_bitrate_key";

NS_ASSUME_NONNULL_BEGIN
@interface ARDSettingsStore () {
  NSUserDefaults *_storage;
}
@property(nonatomic, strong, readonly) NSUserDefaults *storage;
@end

@implementation ARDSettingsStore

- (NSUserDefaults *)storage {
  if (!_storage) {
    _storage = [NSUserDefaults standardUserDefaults];
  }
  return _storage;
}

- (NSString *)videoResolution {
  return [self.storage objectForKey:kVideoResolutionKey];
}

- (void)setVideoResolution:(NSString *)resolution {
  [self.storage setObject:resolution forKey:kVideoResolutionKey];
  [self.storage synchronize];
}

- (NSString *)videoCodec {
  return [self.storage objectForKey:kVideoCodecKey];
}

- (void)setVideoCodec:(NSString *)videoCodec {
  [self.storage setObject:videoCodec forKey:kVideoCodecKey];
  [self.storage synchronize];
}

- (nullable NSNumber *)maxBitrate {
  return [self.storage objectForKey:kBitrateKey];
}

- (void)setMaxBitrate:(nullable NSNumber *)value {
  [self.storage setObject:value forKey:kBitrateKey];
  [self.storage synchronize];
}

@end
NS_ASSUME_NONNULL_END
