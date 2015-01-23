//
//  GPManager.h
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 8/22/13.
//  Copyright (c) 2013 blakerdesign. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface GPMManager : NSObject

+ (GPMManager *)sharedInstance;

- (void)setup;
- (void)togglePlayback;
- (void)previousTrack;
- (void)nextTrack;
- (void)likeTrack;
- (void)dislikeTrack;

@property (nonatomic, strong) NSString *trackName;
@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *albumName;
@property (nonatomic, assign) BOOL isPlaying;

@end
