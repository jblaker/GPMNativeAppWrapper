//
//  Utilities.m
//  GooglePlayMusic
//
//  Created by Jeremy Blaker on 1/22/15.
//  Copyright (c) 2015 blakerdesign. All rights reserved.
//

#import "Utilities.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Utilities

+ (NSString *)md5:(NSString *)input {
  const char *cStr = [input UTF8String];
  unsigned char digest[CC_MD5_DIGEST_LENGTH];
  CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
  
  NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
  
  for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    [output appendFormat:@"%02x", digest[i]];
  
  return  output;
}

@end
