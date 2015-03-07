//
//  CRZLocalizedStringService.h
//  Changeable Test
//
//  Created by Spencer Poff on 1/25/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CRZLocalizedString(KEY) [[CRZLocalizedStringService sharedInstance] stringForKey:KEY]

@interface CRZLocalizedStringService : NSObject

+ (CRZLocalizedStringService *)sharedInstance;

- (NSString *)stringForKey:(NSString *)key;

- (void)updateStringsFromUrl:(NSURL *)stringsURL;

@end
