//
//  SharingManager.m
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 1/22/15.
//  Copyright (c) 2015 blakerdesign. All rights reserved.
//

#import "SharingManager.h"
#import "GPMManager.h"
#import "AFHTTPRequestOperationManager.h"

NSString *const kScrobbleApiKey = @"96d6389e5c462ff06c4c72e7565caa98";
NSString *const kScrobbleApiSecret = @"e2199eb949cd96fc44ac168f49660d5a";
NSString *const kTwitterShareUrl = @"https://twitter.com/intent/tweet";
NSString *const kSessionKey = @"AuthenticatedSessionKey";
NSString *const kScrobbilngEnabledKey = @"ScrobblingIsEnabledKey";

@interface SharingManager ()

@property (nonatomic, strong) NSString *authToken;

@end

@implementation SharingManager

+ (instancetype)hiddenAlloc {
  return [super alloc];
}

+ (instancetype)sharedManager {
  static SharingManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [SharingManager hiddenAlloc];
    [sharedManager setup];
  });
  return sharedManager;
}

- (instancetype)init {
  return [SharingManager sharedManager];
}

- (void)setup {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  bool scrobblingEnabled = [defaults boolForKey:kScrobbilngEnabledKey];
  [_scrobbleShareMenuItem setEnabled:scrobblingEnabled];
}

- (void)shareViaTwitter:(id)sender {
  
  GPMManager *manager = [GPMManager sharedInstance];
  
  if(manager.isPlaying == NO) { return; }
    
  NSString *sharingText = [NSString stringWithFormat:@"Listening to %@ by %@", manager.trackName, manager.artistName];
  sharingText = [sharingText stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
  NSString *sharingURL = [NSString stringWithFormat:@"%@?text=%@", kTwitterShareUrl, sharingText];
  
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:sharingURL]];
  
}

- (void)toggleScrobbling:(id)sender {
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *sessionKey = [defaults objectForKey:kSessionKey];
  
  if(sessionKey == nil) {
    [self getRequestToken];
    return;
  }
  
}

- (void)getRequestToken {
  
  NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=%@&format=json", kScrobbleApiKey];
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

  [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    self.authToken = responseObject[@"token"];
    [self getPermissionFromUser];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"%@", error);
  }];
  
}

- (void)getPermissionFromUser {
  
  NSString *urlString = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@", kScrobbleApiKey, _authToken];
  
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
  
}

@end
