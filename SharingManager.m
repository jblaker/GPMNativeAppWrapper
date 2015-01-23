//
//  SharingManager.m
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 1/22/15.
//  Copyright (c) 2015 blakerdesign. All rights reserved.
//

#import "SharingManager.h"
#import "GPMManager.h"

@implementation SharingManager

+ (instancetype)hiddenAlloc {
  return [super alloc];
}

+ (instancetype)sharedManager {
  static SharingManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [SharingManager hiddenAlloc];
  });
  return sharedManager;
}

- (instancetype)init {
  return [SharingManager sharedManager];
}

- (void)shareViaTwitter:(id)sender {
  
  GPMManager *manager = [GPMManager sharedInstance];
  
  if(manager.isPlaying == NO) { return; }
    
  NSString *sharingText = [NSString stringWithFormat:@"Listening to %@ by %@", manager.trackName, manager.artistName];
  sharingText = [sharingText stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
  NSString *sharingURL = [NSString stringWithFormat:@"https://twitter.com/intent/tweet?text=%@", sharingText];
  
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:sharingURL]];
  
}

- (void)toggleScrobbling:(id)sender {
  
}

@end
