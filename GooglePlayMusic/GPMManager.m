//
//  GPManager.m
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 8/22/13.
//  Copyright (c) 2013 blakerdesign. All rights reserved.
//

#import "GPMManager.h"
#import "AppDelegate.h"
#import "NSString+HTML.h"
#import <AppKit/AppKit.h>

NSString *const kApplicationName = @"Google Play Music";
NSString *const kTrackTitleID = @"playerSongTitle";
NSString *const kArtistID = @"player-artist";
NSString *const kAlbumClass = @"player-album";
NSString *const albumArtId = @"playingAlbumArt";

@interface GPMManager () {
  WebView *_webView;
  NSMenuItem *_nowPlayingMenuItem;
  NSMenuItem *_artistNameMenuItem;
  NSMenuItem *_trackNameMenuItem;
  NSMenuItem *_playbackToggleMenuItem;
  NSMenuItem *_previousTrackMenuItem;
  NSMenuItem *_nextTrackMenuItem;
  NSMenuItem *_likeTrackMenuItem;
  NSMenuItem *_dislikeTrackMenuItem;
  NSMenuItem *_updateStatusMessageMenuItem;
  NSMenu *_dockMenu;
  int _previousTimeStamp;
}

@end

@implementation GPMManager

+ (GPMManager *)sharedInstance {
  static GPMManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GPMManager alloc] init];
  });
  return sharedInstance;
}

- (void)setup {
  
  _nowPlayingMenuItem = [[AppDelegate appDelegate] nowPlayingMenuItem];
  [_nowPlayingMenuItem setTitle:@"Nothing Playing"];
  
  _webView = [[AppDelegate appDelegate] webView];
  [_webView setFrameLoadDelegate:self];
  
  _dockMenu = [[AppDelegate appDelegate] dockMenu];
  _trackNameMenuItem = [[AppDelegate appDelegate] trackNameMenuItem];
  _artistNameMenuItem = [[AppDelegate appDelegate] artistNameMenuItem];
  
  _playbackToggleMenuItem = [[AppDelegate appDelegate] playbackToggleMenuItem];
  _previousTrackMenuItem = [[AppDelegate appDelegate] previousTrackMenuItem];
  _nextTrackMenuItem = [[AppDelegate appDelegate] nextTrackMenuItem];
  _likeTrackMenuItem = [[AppDelegate appDelegate] likeTrackMenuItem];
  _dislikeTrackMenuItem = [[AppDelegate appDelegate] dislikeTrackMenuItem];
  
  [self shouldShowTrackInfoMenuItems:NO];
  [self shouldEnableMenuItems:NO];
  
  [NSTimer scheduledTimerWithTimeInterval:1.01 target:self selector:@selector(displayNowPlaying) userInfo:nil repeats:YES];
  
}

// This delegate method gets triggered every time the page loads, but before the JavaScript runs
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	// Allow this class to be usable through the "window.app" object in JavaScript
	// This could be any Objective-C class
	[windowScriptObject setValue:self forKey:@"app"];
}

- (void)togglePlayback {
  [self triggerJavascriptEvent:@"click" forItemAtIndex:2 inContainer:@"player-middle"];
}

- (void)previousTrack {
  [self triggerJavascriptEvent:@"click" forItemAtIndex:1 inContainer:@"player-middle"];
}

- (void)nextTrack {
  [self triggerJavascriptEvent:@"click" forItemAtIndex:3 inContainer:@"player-middle"];
}

- (void)likeTrack {
  [self triggerJavascriptEvent:@"click" forItemAtIndex:0 inContainer:@"rating-container"];
}

- (void)dislikeTrack {
  [self triggerJavascriptEvent:@"click" forItemAtIndex:1 inContainer:@"rating-container"];
  [self nextTrack];
}

- (void)triggerJavascriptEvent:(NSString *)eventName forItemAtIndex:(int)index inContainer:(NSString *)container {
  NSString *javascriptCommand = [NSString stringWithFormat:@"var event = document.createEvent(\"HTMLEvents\"); event.initEvent(\"%@\", true, true); document.getElementsByClassName('%@')[0].children[%i].dispatchEvent(event)", eventName, container, index];
  [[_webView windowScriptObject] evaluateWebScript:javascriptCommand];
}

- (void)triggerJavascriptEvent:(NSString *)eventName forElementID:(NSString *)elementID {
  NSString *javascriptCommand = [NSString stringWithFormat:@"var event = document.createEvent(\"HTMLEvents\"); event.initEvent(\"%@\", true, true); document.getElementById('%@').dispatchEvent(event)", eventName, elementID];
  [[_webView windowScriptObject] evaluateWebScript:javascriptCommand];
}

- (void)shouldShowTrackInfoMenuItems:(BOOL)b {
  if (b) {
    [_dockMenu insertItem:_trackNameMenuItem atIndex:1];
    [_dockMenu insertItem:_artistNameMenuItem atIndex:2];
  } else {
    [_dockMenu removeItem:_trackNameMenuItem];
    [_dockMenu removeItem:_artistNameMenuItem];
  }
}

- (void)shouldEnableMenuItems:(BOOL)b {
  [_playbackToggleMenuItem setEnabled:b];
  [_previousTrackMenuItem setEnabled:b];
  [_nextTrackMenuItem setEnabled:b];
  [_likeTrackMenuItem setEnabled:b];
  [_dislikeTrackMenuItem setEnabled:b];
}

- (void)displayNowPlaying {
  
  NSString *currentTrackName = [self innerHTMLForElementWithID:kTrackTitleID];
  if ( ![currentTrackName isEqualToString:_trackName] ) {
    _previousTimeStamp = 0;
  }
  _trackName = currentTrackName;
  _artistName = [self innerHTMLForElementWithID:kArtistID];
  _albumName = [self innerHTMLForElementWithClassName:kAlbumClass atIndex:0];
  
  if ( _trackName.length == 0 ) {
    [_nowPlayingMenuItem setTitle:@"Nothing Playing"];
    if ( _isPlaying == YES ) {
      [self shouldShowTrackInfoMenuItems:NO];
      [self shouldEnableMenuItems:NO];
      _isPlaying = NO;
    }
  } else {
    if([self updateMenuItem:_trackNameMenuItem withTitle:[_trackName kv_decodeHTMLCharacterEntities]]){
      [self postNotification];
    }
    [self updateMenuItem:_artistNameMenuItem withTitle:[_artistName kv_decodeHTMLCharacterEntities]];
    [self updateMenuItem:_nowPlayingMenuItem withTitle:@"Now Playing"];
    
    if ( _isPlaying == NO && _previousTimeStamp != 0 ) {
      [self shouldShowTrackInfoMenuItems:YES];
      [self shouldEnableMenuItems:YES];
      _isPlaying = YES;
    }
    
    NSString *currentTimeString = [self innerHTMLForElementWithID:@"time_container_current"];
    int currentTimeStamp = [[currentTimeString stringByReplacingOccurrencesOfString:@":" withString:@""] intValue];
    if ( currentTimeStamp > _previousTimeStamp ) {
      [self updateMenuItem:_playbackToggleMenuItem withTitle:@"Pause"];
    } else {
      [self updateMenuItem:_playbackToggleMenuItem withTitle:@"Play"];
    }
    _previousTimeStamp = currentTimeStamp;
    
  }

}

- (void)postNotification {
  
  NSURL *imageURL = [NSURL URLWithString:[self attributeValueForAtribute:@"src" forElementWithID:albumArtId]];
  
  dispatch_queue_t notificationQueue = dispatch_queue_create("com.blakerdesign.notifications", NULL);
  
  dispatch_async(notificationQueue, ^{
    
    NSImage *albumArtImage = [[NSImage alloc] initWithContentsOfURL:imageURL];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
      NSUserNotification *notification = [[NSUserNotification alloc] init];
      notification.title = _trackName;
      
      notification.contentImage = albumArtImage;
      notification.informativeText = [NSString stringWithFormat:@"%@ — %@", [_artistName kv_decodeHTMLCharacterEntities], [_albumName kv_decodeHTMLCharacterEntities]];
      [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
      [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
      
    });
    
  });
  
}

- (BOOL)updateMenuItem:(NSMenuItem *)menuItem withTitle:(NSString *)title {
  if ( ![[menuItem title] isEqualToString:title] ) {
    [menuItem setTitle:title];
    return YES;
  }
  return NO;
}

- (NSString *)innerHTMLForElementWithClassName:(NSString *)className atIndex:(int)index {
  return [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementsByClassName('%@')[%i].innerHTML", className, index]];
}

- (NSString *)innerHTMLForElementWithID:(NSString *)idName {
  return [_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('%@').innerHTML", idName]];
}

- (NSString *)attributeValueForAtribute:(NSString *)attribute forElementWithID:(NSString *)idName {
  NSString *javascript = [NSString stringWithFormat:@"document.getElementById('%@').%@", idName, attribute];
  NSString *result = [_webView stringByEvaluatingJavaScriptFromString:javascript];
  return result;
}

@end
