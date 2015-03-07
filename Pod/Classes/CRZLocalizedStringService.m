//
//  CRZLocalizedStringService.m
//  Changeable Test
//
//  Created by Spencer Poff on 1/25/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import "CRZLocalizedStringService.h"

// Data
#import "LocalizedString+CRZExtensions.h"
#import "Translation.h"

static NSString *const kCRZPodName = @"CtrlZ";

static NSString *const kCTChangeableStringsGoogleSheetKey = @"1lkYaN3pf5FzAnBEJEh7kFIKGIpEHwUwU0YNDrgq4Vmw";

static NSString *const kCRZLocalizedStringKey = @"key";
static NSString *const kCRZTranslationsKey = @"translations";
static NSString *const kCRZLanguageIDKey = @"languageID";
static NSString *const kCRZTranslationValueKey = @"value";

@interface CRZLocalizedStringService ()

// Core Data
@property (nonatomic, strong, readwrite) NSManagedObjectModel            *managedObjectModel;
@property (nonatomic, strong, readwrite) NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

@property (nonatomic, copy) NSString *modelConfiguration;
@property (nonatomic, copy) NSString *storeType;
@property (nonatomic, copy) NSURL    *storeURL;

@end

@implementation CRZLocalizedStringService

+ (CRZLocalizedStringService *)sharedInstance
{
    static CRZLocalizedStringService *crzService = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crzService = [[CRZLocalizedStringService alloc] init];
    });
    
    return crzService;
}

- (instancetype)init
{
    self = [super init];
    
    if ( self ) {
        self.storeType = NSSQLiteStoreType;
        [self buildCoreDataStack];
    }
    
    return self;
}

- (NSString *)stringForKey:(NSString *)key
{
    NSString *stringToDisplay = key;
    
    LocalizedString *localizedString = [self localizedStringObjectForKey:key];
    
    if ( localizedString ) {
        NSString *langKey = [[NSLocale preferredLanguages] firstObject];
        NSPredicate *currentTranslationPredicate = [NSPredicate predicateWithFormat:@"%K MATCHES[c] %@", kCRZLanguageIDKey, langKey];
        NSArray *translations = [[localizedString.translations filteredSetUsingPredicate:currentTranslationPredicate] allObjects];
        if ( [translations count] ) {
            Translation *translation = [translations firstObject];
            stringToDisplay = translation.value;
        }
    }
    else {
        stringToDisplay = NSLocalizedString(key, nil);
    }
    return stringToDisplay;
}

- (void)updateStringsFromUrl:(NSURL *)stringsURL
{
    
    NSURLRequest *stringRequest = [NSURLRequest requestWithURL:stringsURL];
    
    [NSURLConnection sendAsynchronousRequest:stringRequest queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if ( !connectionError ) {
            NSDictionary *stringsDict = [self localizedStringsFromJSONData:data];
            [self performSelectorOnMainThread:@selector(saveStringsDict:) withObject:stringsDict waitUntilDone:YES];
        }
    }];
}

- (LocalizedString *)localizedStringObjectForKey:(NSString *)key
{
    LocalizedString *string = nil;
    
    // Create predicate
    NSPredicate *stringWithKeyPredicate = [NSPredicate predicateWithFormat:@"%K MATCHES[c] %@", kCRZLocalizedStringKey, key];
    
    // Find entity name
    NSString *className = NSStringFromClass([LocalizedString class]);
    NSString *entityName = nil;
    for ( NSEntityDescription *entity in self.managedObjectModel.entities ) {
        if ( [entity.managedObjectClassName isEqualToString:className] ) {
            entityName = entity.name;
            break;
        }
    }
    
    // Create fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;
    fetchRequest.predicate = stringWithKeyPredicate;
    
    // Execute fetch request
    NSError *error = nil;
    NSArray *newStrings = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if ( error ) {
        NSLog(@"Error performing fetch: %@", error);
    }
    
    if ( [newStrings count] ) {
        string = [newStrings firstObject];
    }
    
    // Create new LocalizedString object if none found
    if ( !string ) {
        NSString *className = NSStringFromClass([LocalizedString class]);
        NSString *entityName = nil;
        for ( NSEntityDescription *entity in self.managedObjectModel.entities ) {
            if ( [entity.managedObjectClassName isEqualToString:className] ) {
                entityName = entity.name;
                break;
            }
        }
        string = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
        string.key = key;
    }
    
    return string;
}

// TODO: Modify the following constant and method depending on data source
//static NSString *const kCTChangeableStringsLiveTextKeyBase = @"gsx$livetext";

- (NSDictionary *)localizedStringsFromJSONData:(NSData *)data
{
    NSDictionary *localizedStringsDict = [[NSDictionary alloc] init];
    
    NSError *error = nil;
    localizedStringsDict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if ( error ) {
        NSLog(@"JSON Serialization failed with error: %@", error);
    }
    
    return localizedStringsDict;
}

- (void)saveStringsDict:(NSDictionary *)stringsDict
{
    for ( id stringKey in stringsDict ) {
        // Convert key to string
        NSString *shippedText;
        if ( [stringKey isKindOfClass:[NSString class]] ) {
            shippedText = (NSString *)stringKey;
        }
        
        if ( shippedText.length ) {
            // Fetch saved string that matches key found in payload.
            LocalizedString *savedString = [self localizedStringObjectForKey:shippedText];
            
            NSDictionary *translationsDict = [stringsDict objectForKey:stringKey];
            
            for ( id languageIdKey in translationsDict ) {
                // Convert key to string
                NSString *languageId;
                if ( [languageIdKey isKindOfClass:[NSString class]] ) {
                    languageId = (NSString *)languageIdKey;
                }
                
                NSString *translatedString = [[stringsDict objectForKey:stringKey] objectForKey:languageIdKey];
                
                if ( translatedString.length && ![shippedText isEqualToString:translatedString] ) {
                    // Fetch saved translation for current language ID
                    Translation *savedTranslation = [savedString translationForLanguageKey:languageId];
                    
                    // Create a new Translation object if none was found
                    if ( !savedTranslation ) {
                        NSString *className = NSStringFromClass([Translation class]);
                        NSString *entityName = nil;
                        for ( NSEntityDescription *entity in self.managedObjectModel.entities ) {
                            if ( [entity.managedObjectClassName isEqualToString:className] ) {
                                entityName = entity.name;
                                break;
                            }
                        }
                        savedTranslation = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
                        savedTranslation.languageID = languageId;
                        [savedString addTranslationsObject:savedTranslation];
                    }
                    
                    savedTranslation.value = translatedString;
                    
                    NSError *error;
                    [self.managedObjectContext save:&error];
                    if ( error ) {
                        NSLog(@"Failed to save localized string with error: %@", error);
                    }
                }
            }
        }
    }
}

#pragma mark - Bundle Resources

- (NSBundle *)podBundle
{
    return [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:kCRZPodName withExtension:@"bundle"]];
}

#pragma mark - Core Data
// Much of this code taken from RZVinyl ( https://github.com/Raizlabs/RZVinyl )

- (NSURL *)storeURL
{
    if (_storeURL == nil) {
        if ( [self.storeType isEqualToString:NSSQLiteStoreType] ) {
            NSString *storeFileName = [kCRZPodName stringByAppendingPathExtension:@"sqlite"];
            NSURL    *libraryDir = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
            _storeURL = [libraryDir URLByAppendingPathComponent:storeFileName];
        }
    }
    return _storeURL;
}

- (BOOL)buildCoreDataStack
{
    //
    // Create model
    //
    if ( self.managedObjectModel == nil ) {
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[self podBundle] URLForResource:kCRZPodName withExtension:@"momd"]];
        if ( self.managedObjectModel == nil ) {
            NSLog(@"Could not create managed object model for name %@", kCRZPodName);
            return NO;
        }
    }
    
    //
    // Create PSC
    //
    NSError *error = nil;
    if ( self.persistentStoreCoordinator == nil ) {
        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    }
    
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    
    if ( self.storeType == NSSQLiteStoreType ) {
        NSAssert(self.storeURL != nil, @"Must have a store URL for SQLite stores");
        if ( self.storeURL == nil ) {
            return NO;
        }
        options[NSSQLitePragmasOption] = @{@"journal_mode" : @"WAL"};
    }
    
    if ( self.storeURL ){
        options[NSMigratePersistentStoresAutomaticallyOption] = @(YES);
        options[NSInferMappingModelAutomaticallyOption] = @(YES);
    }
    
    if( ![self.persistentStoreCoordinator addPersistentStoreWithType:self.storeType
                                                       configuration:self.modelConfiguration
                                                                 URL:self.storeURL
                                                             options:options
                                                               error:&error] ) {
        
        NSLog(@"Error creating/reading persistent store: %@", error);
        
        if ( self.storeURL ) {
            
            // Reset the error before we reuse it
            error = nil;
            
            if ( [[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:&error] ) {
                
                [self.persistentStoreCoordinator addPersistentStoreWithType:self.storeType
                                                              configuration:self.modelConfiguration
                                                                        URL:self.storeURL
                                                                    options:options
                                                                      error:&error];
            }
        }
        
        if ( error != nil ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"Unresolved error creating PSC for data stack: %@", error]
                                         userInfo:nil];
            return NO;
        }
    }
    
    //
    // Create Context
    //
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    
    return YES;
}

@end
