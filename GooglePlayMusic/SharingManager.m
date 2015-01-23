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
#import "Utilities.h"

NSString *const kScrobbleApiKey = @"";
NSString *const kScrobbleApiSecret = @"";
NSString *const kTwitterShareUrl = @"https://twitter.com/intent/tweet";
NSString *const kSessionKey = @"AuthenticatedSessionKey";
NSString *const kScrobbilngEnabledKey = @"ScrobblingIsEnabledKey";
//NSString *const kLastFmUsernameKey = @"LastFmUsername";

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
  });
  return sharedManager;
}

- (instancetype)init {
  return [SharingManager sharedManager];
}

- (void)awakeFromNib {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL scrobblingEnabled = [defaults boolForKey:kScrobbilngEnabledKey];
  if(scrobblingEnabled) {
    [_scrobbleShareMenuItem setState:1];
  } else {
    [_scrobbleShareMenuItem setState:0];
  }
}

- (void)shareViaTwitter:(id)sender {
  
  GPMManager *manager = [GPMManager sharedInstance];
  
  if(manager.isPlaying == NO) { return; }
    
  NSString *sharingText = [NSString stringWithFormat:@"I'm listening to %@ by %@", manager.trackName, manager.artistName];
  sharingText = [sharingText stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
  NSString *sharingURL = [NSString stringWithFormat:@"%@?text=%@", kTwitterShareUrl, sharingText];
  
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:sharingURL]];
  
}

- (void)toggleScrobbling:(id)sender {
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL scrobblingEnabled = [defaults boolForKey:kScrobbilngEnabledKey];
  
  if(scrobblingEnabled) {
    [defaults setBool:NO forKey:kScrobbilngEnabledKey];
    //[defaults setObject:nil forKey:kSessionKey];
    [defaults synchronize];
    [_scrobbleShareMenuItem setState:0];
    return;
  }
  
  NSString *sessionKey = [defaults objectForKey:kSessionKey];
  
  if(sessionKey == nil) {
    [self getRequestToken:nil];
    return;
  }
  
}

- (void)getRequestToken:(void (^)(void))callback {
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *sessionKey = [defaults objectForKey:kSessionKey];
  NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=auth.gettoken&api_key=%@&format=json", kScrobbleApiKey];
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

  [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    DLog(@"%@", responseObject);
    self.authToken = responseObject[@"token"];
    if(sessionKey == nil) {
      [self getPermissionFromUser];
    }
    if(callback) {
      callback();
    }
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    DLog(@"%@", error);
  }];
  
}

- (void)getPermissionFromUser {
  
  NSString *urlString = [NSString stringWithFormat:@"http://www.last.fm/api/auth/?api_key=%@&token=%@", kScrobbleApiKey, _authToken];
  
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReturnFromAuthorizing:) name:@"ApplicationDidBecomeActive" object:nil];
  
}

- (void)didReturnFromAuthorizing:(NSNotification *)notification {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [self getSessionKey];

}

- (void)getSessionKey {
  
  NSString *preMD5 = [NSString stringWithFormat:@"api_key%@methodauth.getSessiontoken%@%@", kScrobbleApiKey, _authToken, kScrobbleApiSecret];
  
  NSString *urlString = [NSString stringWithFormat:@"http://ws.audioscrobbler.com/2.0/?method=auth.getSession&api_key=%@&token=%@&api_sig=%@&format=json", kScrobbleApiKey, _authToken, [Utilities md5:preMD5]];
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  
  [manager GET:urlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    // TODO: Verify there is a key
    DLog(@"Saving session key: %@", responseObject[@"session"][@"key"]);
    [self setSessionKey:responseObject[@"session"][@"key"]];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    DLog(@"%@", error);
  }];
  
}

- (void)setSessionKey:(NSString *)sessionKey {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:sessionKey forKey:kSessionKey];
  [defaults setBool:YES forKey:kScrobbilngEnabledKey];
  [defaults synchronize];
}

+ (void)scrobbleNowPlayingTrack:(NSString *)trackName byArtist:(NSString *)artistName {
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL scrobblingEnabled = [defaults boolForKey:kScrobbilngEnabledKey];
  
  if(scrobblingEnabled == NO) { return; }
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  
  NSString *preMD5ApiSig = [NSString stringWithFormat:@"api_key%@artist%@methodtrack.updateNowPlayingsk%@track%@%@", kScrobbleApiKey, artistName, [defaults objectForKey:kSessionKey], trackName, kScrobbleApiSecret];
  
  NSDictionary *postBody = @{@"method": @"track.updateNowPlaying",
                             @"artist": artistName,
                             @"track": trackName,
                             @"api_key": kScrobbleApiKey,
                             @"api_sig":[Utilities md5:preMD5ApiSig],
                             @"sk": [defaults objectForKey:kSessionKey]};
  
  [manager POST:@"http://ws.audioscrobbler.com/2.0/?format=json" parameters:postBody success:^(AFHTTPRequestOperation *operation, id responseObject) {
    DLog(@"%@", responseObject);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    DLog(@"%@", error);
  }];
  
}

+ (void)scrobblePlayedTrack:(NSString *)trackName byArtist:(NSString *)artistName {
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL scrobblingEnabled = [defaults boolForKey:kScrobbilngEnabledKey];
  
  if(scrobblingEnabled == NO) { return; }
  
  long timestamp = [[NSDate date] timeIntervalSince1970];
  
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  
  NSString *preMD5ApiSig = [NSString stringWithFormat:@"api_key%@artist%@methodtrack.scrobblesk%@timestamp%@track%@%@", kScrobbleApiKey, artistName, [defaults objectForKey:kSessionKey], [NSNumber numberWithLong:timestamp], trackName, kScrobbleApiSecret];
  
  NSDictionary *postBody = @{@"method": @"track.scrobble",
                             @"artist": artistName,
                             @"track": trackName,
                             @"timestamp": [NSNumber numberWithLong:timestamp],
                             @"api_key": kScrobbleApiKey,
                             @"api_sig":[Utilities md5:preMD5ApiSig],
                             @"sk": [defaults objectForKey:kSessionKey]};
  
  [manager POST:@"http://ws.audioscrobbler.com/2.0/?format=json" parameters:postBody success:^(AFHTTPRequestOperation *operation, id responseObject) {
    DLog(@"%@", responseObject);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    DLog(@"%@", error);
  }];
  
}

@end
