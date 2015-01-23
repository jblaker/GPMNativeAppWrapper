//
//  SharingManager.h
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 1/22/15.
//  Copyright (c) 2015 blakerdesign. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SharingManager : NSObject

@property (nonatomic, weak) IBOutlet NSMenuItem *scrobbleShareMenuItem;

- (IBAction)shareViaTwitter:(id)sender;
- (IBAction)toggleScrobbling:(id)sender;

+ (instancetype)sharedManager;

@end
