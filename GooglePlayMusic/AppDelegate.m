//
//  AppDelegate.m
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 8/20/13.
//  Copyright (c) 2013 blakerdesign. All rights reserved.
//

#import "AppDelegate.h"
#import "GPMManager.h"
#import "AppleMediaKeyController.h"

NSString *const kURLToLoad = @"https://play.google.com/music/listen";

@implementation AppDelegate

@synthesize webView, window;

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  
  [self setupAppleMediaController];

  [webView setMainFrameURL:kURLToLoad];
  
  [[GPMManager sharedInstance] setup];
}

- (void)setupAppleMediaController {
  
  [AppleMediaKeyController sharedController];
  
  GPMManager *manager = [GPMManager sharedInstance];
  
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:manager selector:@selector(togglePlayback) name:MediaKeyPlayPauseNotification object:nil];
  [center addObserver:manager selector:@selector(nextTrack) name:MediaKeyNextNotification object:nil];
  [center addObserver:manager selector:@selector(previousTrack) name:MediaKeyPreviousNotification object:nil];
  
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self bringMainWindowToFront:nil];
	return YES;
}

- (void)bringMainWindowToFront:(id)sender {
	[window makeKeyAndOrderFront:sender];
	if ([[webView mainFrameURL] isEqualTo:@""]) {
		[webView setMainFrameURL:kURLToLoad];
	}
}

+ (AppDelegate *)appDelegate {
	return (AppDelegate *)[[NSApplication sharedApplication] delegate];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
}

#pragma mark - UI Actions

- (void)togglePlaybackFromStatusBar:(id)sender {
  [[GPMManager sharedInstance] togglePlayback];
}

- (void)nextTrackFromStatusBar:(id)sender {
  [[GPMManager sharedInstance] nextTrack];
}

- (IBAction)togglePlayback:(id)sender {
  [[GPMManager sharedInstance] togglePlayback];
}

- (IBAction)nextTrack:(id)sender {
  [[GPMManager sharedInstance] nextTrack];
}

- (IBAction)previousTrack:(id)sender {
  [[GPMManager sharedInstance] previousTrack];
}

- (IBAction)likeTrack:(id)sender {
  [[GPMManager sharedInstance] likeTrack];
}

- (IBAction)dislikeTrack:(id)sender {
  [[GPMManager sharedInstance] dislikeTrack];
}

@end