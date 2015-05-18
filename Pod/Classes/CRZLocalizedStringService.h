//
//  CRZLocalizedStringService.h
//  Changeable Test
//
//  Created by Spencer Poff on 1/25/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CRZLocalizedString(KEY) [CRZLocalizedStringService stringForKey:KEY]

@interface CRZLocalizedStringService : NSObject

/**
 *  Grabs a translation for a given string according to the device's current language settings, either from the strings in the bundle or the value downloaded from the server, or returns the key if none of the above are available.
 *
 *  @param key  The string for which to fetch the translation.
 *
 *  @return Translation for the given string.
 */
+ (NSString *)stringForKey:(NSString *)key;

/**
 *  Updates the string translations based on the JSON file found at the supplied URL.
 *
 * @param stringsURL    The full HTTP address from which to pull the strings JSON payload.
 */
+ (void)updateStringsFromUrl:(NSURL *)stringsURL;

@end
