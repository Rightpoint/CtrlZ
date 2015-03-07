//
//  LocalizedString+CRZExtensions.h
//  Pods
//
//  Created by Spencer Poff on 3/6/15.
//
//

#import "LocalizedString.h"

@class Translation;

@interface LocalizedString (CRZExtensions)

- (Translation *)translationForLanguageKey:(NSString *)languageKey;

@end
