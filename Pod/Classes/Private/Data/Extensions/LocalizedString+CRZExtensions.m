//
//  LocalizedString+CRZExtensions.m
//  Pods
//
//  Created by Spencer Poff on 3/6/15.
//
//

#import "LocalizedString+CRZExtensions.h"

#import "Translation.h"

static NSString *const kCRZLanguageIDKey = @"languageID";

@implementation LocalizedString (CRZExtensions)

- (Translation *)translationForLanguageKey:(NSString *)languageKey
{
    Translation *translation = nil;
    
    NSPredicate *translationForCurrentLanguagePredicate = [NSPredicate predicateWithFormat:@"%K MATCHES[c] %@", kCRZLanguageIDKey, languageKey];
    NSSet *translationsForCurrentLanguage = [self.translations filteredSetUsingPredicate:translationForCurrentLanguagePredicate];
    
    if ( [translationsForCurrentLanguage count] > 1 ) {
        NSSortDescriptor *soonestFirst = [NSSortDescriptor sortDescriptorWithKey:@"dateModified" ascending:NO];
        NSArray *sortedByDate = [[translationsForCurrentLanguage allObjects] sortedArrayUsingDescriptors:@[soonestFirst]];
        translation = [sortedByDate firstObject];
        [self removeTranslations:translationsForCurrentLanguage];
        [self addTranslationsObject:translation];
    }
    else {
        translation = [[translationsForCurrentLanguage allObjects] firstObject];
    }
    
    return translation;
}

@end
