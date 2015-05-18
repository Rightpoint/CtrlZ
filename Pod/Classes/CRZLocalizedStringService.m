//
//  CRZLocalizedStringService.m
//  Changeable Test
//
//  Created by Spencer Poff on 1/25/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import "CRZLocalizedStringService.h"

// Data
#import "CRZTranslations.h"

static NSString *const kCRZUserDefaultsLastUpdatedTimestampKey = @"CRZTranslationsLastUpdatedTimestamp";

static NSString *const kCRZPayloadLastUpdatedTimestampKey   = @"lastUpdatedTimestamp";
static NSString *const kCRZPayloadTranslationsKey           = @"translations";

@implementation CRZLocalizedStringService

#pragma mark - Public

+ (NSString *)stringForKey:(NSString *)key
{
    // Default to localized string baked into the bundle
    NSString *stringToDisplay = [[NSBundle mainBundle] localizedStringForKey:key value:nil table:nil];
    
    
    NSString *crzLocalizedString = [CRZLocalizedStringService localizedStringForKey:key];
    if ( crzLocalizedString.length ) {
        stringToDisplay = crzLocalizedString;
    }
    
    return stringToDisplay;
}

+ (void)updateStringsFromUrl:(NSURL *)stringsURL
{
    NSURLRequest *stringRequest = [NSURLRequest requestWithURL:stringsURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0];
    
    [NSURLConnection sendAsynchronousRequest:stringRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if ( !connectionError && data ) {
            NSError *serializationError = nil;
            id serializedJSONData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
            
            if ( !connectionError && !serializationError && [CRZLocalizedStringService shouldSaveJSONObject:serializedJSONData] ) {
                NSArray *translationsArray = [CRZLocalizedStringService translationsArrayFromJSONObject:serializedJSONData];
                
                // TODO: Save translations for current language in memory for speed
                
                [CRZLocalizedStringService clearExistingTranslations];
                
                for ( CRZTranslations *translationsObject in translationsArray ) {
                    BOOL savedSuccessfully = [CRZLocalizedStringService saveTranslationsObject:translationsObject];
                    
                    if ( savedSuccessfully ) {
                        NSInteger lastUpdatedTimestamp = [CRZLocalizedStringService lastUpdatedTimestampFromJSONObject:serializedJSONData];
                        
                        if ( lastUpdatedTimestamp > 0 ) {
                            [CRZLocalizedStringService saveExistingTranslationsLastUpdatedTimestamp:lastUpdatedTimestamp];
                        }
                    }
                }
            }
            else if ( serializationError ) {
                NSLog(@"CtrlZ - ERROR - JSON Serialization failed with error: %@", serializationError); // TODO: Throw real errors
            }
        }
        else {
            NSLog(@"CtrlZ - ERROR - Translations download failed with error: %@", connectionError);
        }
    }];
}

#pragma mark - Accessing

+ (NSString *)localizedStringForKey:(NSString *)key
{
    return [self localizedStringForKey:key withLanguageID:nil];
}

+ (NSString *)localizedStringForKey:(NSString *)key withLanguageID:(NSString *)languageID
{
    if ( !languageID.length ) {
        languageID = [[[NSBundle mainBundle] preferredLocalizations] firstObject];
    }
    
    NSDictionary *languageSpecificTranslationsDict = [self translationsDictForLanguageID:languageID];
    
    return [languageSpecificTranslationsDict objectForKey:key];
}

+ (NSDictionary *)translationsDictForLanguageID:(NSString *)languageID
{
    NSString *translationsPlistPath = [self translationsFilePathForLanguageID:languageID];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ( ![fileManager fileExistsAtPath:translationsPlistPath] ) {
        return nil;
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:translationsPlistPath];
}

#pragma mark - Saving

+ (BOOL)shouldSaveJSONObject:(id)JSONObject
{
    BOOL shouldSave = NO;
    
    if ( [JSONObject isKindOfClass:[NSDictionary class]] ) {
        NSNumber *payloadLastUpdatedTimestamp = [(NSDictionary *)JSONObject objectForKey:kCRZPayloadLastUpdatedTimestampKey];
        
        if ( payloadLastUpdatedTimestamp.integerValue > [CRZLocalizedStringService existingTranslationsLastUpdatedTimestamp] ) {
            shouldSave = YES;
        }
    }
    
    return shouldSave;
}

+ (NSArray *)translationsArrayFromJSONObject:(id)JSONObject
{
    NSArray *translationsArray = nil;
    
    if ( [JSONObject isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *dictOfTranslationsDicts = [(NSDictionary *)JSONObject objectForKey:kCRZPayloadTranslationsKey];
        NSMutableArray *mutableTranslationsArray = [[NSMutableArray alloc] init];
        
        for ( NSString *langIDKey in dictOfTranslationsDicts ) {
            CRZTranslations *translationsObject = [[CRZTranslations alloc] init];
            translationsObject.languageID = langIDKey;
            translationsObject.translationsDictionary = (NSDictionary *)dictOfTranslationsDicts[langIDKey];
            
            [mutableTranslationsArray addObject:translationsObject];
        }
        
        translationsArray = mutableTranslationsArray;
    }
    else {
        NSLog(@"CtrlZ - ERROR - Expected dictionary from JSON object, unknown data structure found.");
    }
    
    return translationsArray;
}

+ (NSInteger)lastUpdatedTimestampFromJSONObject:(id)JSONObject
{
    NSInteger lastUpdatedTimestamp = -1;
    
    if ( [JSONObject isKindOfClass:[NSDictionary class]] ) {
        NSNumber *lastUpdatedTimestampObject = [(NSDictionary *)JSONObject objectForKey:kCRZPayloadLastUpdatedTimestampKey];
        lastUpdatedTimestamp = lastUpdatedTimestampObject.integerValue;
    }
    else {
        NSLog(@"CtrlZ - ERROR - Expected dictionary from JSON object, unknown data structure found.");
    }
    
    return lastUpdatedTimestamp;
}

+ (BOOL)saveTranslationsObject:(CRZTranslations *)translations
{
    NSString *translationsPlistPath = [CRZLocalizedStringService translationsFilePathForLanguageID:translations.languageID];
    
    if ( [[NSFileManager defaultManager] isWritableFileAtPath:translationsPlistPath] ) {
        [translations.translationsDictionary writeToFile:translationsPlistPath atomically:YES];
    }
    
    return [translations.translationsDictionary writeToFile:translationsPlistPath atomically:YES];
}

+ (BOOL)clearExistingTranslations
{
    BOOL successful = NO;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    NSArray *savedTranslationsFiles = [fileManager contentsOfDirectoryAtPath:[self directoryPath]  error:&error];
    
    if ( !error ) {
        successful = YES;
        
        for ( NSString *savedTranslationFilename in savedTranslationsFiles ) {
            [fileManager removeItemAtPath:[[self directoryPath] stringByAppendingPathComponent:savedTranslationFilename] error:&error];
            
            if ( error ) {
                successful = NO;
                
                NSLog(@"CtrlZ - ERROR - Removing file failed with error: %@", error);
            }
        }
    }
    else {
        NSLog(@"CtrlZ - ERROR - Reading contents of directory failed with error: %@", error);
    }
    
    return successful;
}

#pragma mark - Convenience Accessors

+ (NSInteger)existingTranslationsLastUpdatedTimestamp
{
    return [(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:kCRZUserDefaultsLastUpdatedTimestampKey] integerValue];
}

+ (void)saveExistingTranslationsLastUpdatedTimestamp:(NSInteger)lastUpdatedTimestamp
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:lastUpdatedTimestamp] forKey:kCRZUserDefaultsLastUpdatedTimestampKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)translationsFilePathForLanguageID:(NSString *)languageID
{
    NSString *crzDirectoryPath = [self directoryPath];
    NSString *translationsPlistFilename = [NSString stringWithFormat:@"crz_%@.plist", languageID];
    return [crzDirectoryPath stringByAppendingPathComponent:translationsPlistFilename];
}

+ (NSString *)directoryPath
{
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *directoryPath = [libraryPath stringByAppendingPathComponent:@"CtrlZ/"];
    
    // Only creates directory if it does not already exist.
    BOOL success = [CRZLocalizedStringService createDirectoryWithPath:directoryPath];
    
    if ( !success ) {
        directoryPath = nil;
    }
    
    return directoryPath;
}

+ (BOOL)createDirectoryWithPath:(NSString *)directoryPath
{
    BOOL createdSuccessfully = NO;
    
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    if ( !error ) {
        createdSuccessfully = YES;
    }
    else {
        NSLog(@"CtrlZ - ERROR - Creating directory failed with error: %@", error);
    }
    
    return createdSuccessfully;
}

@end
