//
//  CRZLocalizedStringService.m
//  Changeable Test
//
//  Created by Spencer Poff on 1/25/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import "CRZLocalizedStringService.h"

// Data
#import "LocalizedString.h"
#import "Translation.h"

static NSString *const kCTChangeableStringsGoogleSheetKey = @"1lkYaN3pf5FzAnBEJEh7kFIKGIpEHwUwU0YNDrgq4Vmw";

static NSString *const kCRZLocalizedStringKey = @"key";
static NSString *const kCRZTranslationsKey = @"translations";
static NSString *const kCRZLanguageIDKey = @"languageID";
static NSString *const kCRZTranslationValueKey = @"value";

@interface CRZLocalizedStringService ()

@property (nonatomic, strong, readwrite) NSManagedObjectModel            *managedObjectModel;
@property (nonatomic, strong, readwrite) NSManagedObjectContext          *managedObjectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator    *persistentStoreCoordinator;

@property (nonatomic, copy) NSString *modelConfiguration;
@property (nonatomic, copy) NSString *storeType;
@property (nonatomic, copy) NSURL    *storeURL;
@property (nonatomic, strong) dispatch_queue_t backgroundContextQueue;

@property (nonatomic, readonly, strong) NSDictionary *entityClassNamesToStalenessPredicates;

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

- (void)updateStrings
{
    NSURL *spreadsheetURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://spreadsheets.google.com/feeds/list/%@/1/public/full?alt=json", kCTChangeableStringsGoogleSheetKey]];
    
    NSURLRequest *stringRequest = [NSURLRequest requestWithURL:spreadsheetURL];
    
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
    
    return string;
}

// TODO: Modify the following constant and method depending on data source
static NSString *const kCTChangeableStringsLiveTextKeyBase = @"gsx$livetext";

- (NSDictionary *)localizedStringsFromJSONData:(NSData *)data
{
    NSMutableDictionary *localizedStringsDict = [[NSMutableDictionary alloc] init];
    
    NSError *error = nil;
    id localizedStringsJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if ( localizedStringsJSON != nil && [localizedStringsJSON isKindOfClass:[NSDictionary class]] ) {
        for ( NSDictionary *entry in localizedStringsJSON[@"feed"][@"entry"] ) {
//            NSLog(@"Entry: %@", entry);
            
            NSString *shippedText = entry[@"gsx$shippedtext"][@"$t"];
            NSLog(@"Shipped text: %@", shippedText);
            
            NSString *currentLangID = [[NSLocale preferredLanguages] firstObject];
            
            // Default to english
            NSString *newTextKey = [NSString stringWithFormat:@"%@%@", kCTChangeableStringsLiveTextKeyBase, currentLangID];
            NSString *newText = entry[newTextKey][@"$t"];
            NSLog(@"New text: %@", newText);
            
            // TODO: This should be populated with the translation for each language
            NSDictionary *translationsDict = @{ currentLangID : newText };
            
            [localizedStringsDict setValue:translationsDict forKey:shippedText];
        }
    }
    
    return localizedStringsDict;
}

- (void)saveStringsDict:(NSDictionary *)stringsDict
{
    NSArray *stringKeys = [stringsDict allKeys];
    
    for ( NSString *stringKey in stringKeys ) {
        
        NSString *currentLangID = [[NSLocale preferredLanguages] firstObject];
        NSString *newString = stringsDict[stringKey][currentLangID];
        
        if ( stringKey && newString && ![stringKey isEqualToString:newString] ) {
            // TODO: why is localizedStringObjectForKey returning nil?
            LocalizedString *stringToChange = [self localizedStringObjectForKey:stringKey];
            Translation *translation = nil;
            if ( !stringToChange ) {
                // Create new LocalizedString object
                NSString *className = NSStringFromClass([LocalizedString class]);
                NSString *entityName = nil;
                for ( NSEntityDescription *entity in self.managedObjectModel.entities ) {
                    if ( [entity.managedObjectClassName isEqualToString:className] ) {
                        entityName = entity.name;
                        break;
                    }
                }
                stringToChange = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
                stringToChange.key = stringKey;
            }
            else {
                // TODO: Add validation to make sure there is only one translation for the given language, and remove all but one if multiple are found
                NSPredicate *translationForCurrentLanguagePredicate = [NSPredicate predicateWithFormat:@"%K MATCHES[c] %@", kCRZLanguageIDKey, currentLangID];
                NSSet *translationsForCurrentLanguage = [stringToChange.translations filteredSetUsingPredicate:translationForCurrentLanguagePredicate];
                if ( [translationsForCurrentLanguage count] > 1 ) {
                    NSSortDescriptor *soonestFirst = [NSSortDescriptor sortDescriptorWithKey:@"dateModified" ascending:NO];
                    NSArray *sortedByDate = [[translationsForCurrentLanguage allObjects] sortedArrayUsingDescriptors:@[soonestFirst]];
                    translation = [sortedByDate firstObject];
                    [stringToChange removeTranslations:translationsForCurrentLanguage];
                    [stringToChange addTranslationsObject:translation];
                }
                else {
                    translation = [[translationsForCurrentLanguage allObjects] firstObject];
                }
            }
            
            if ( !translation ) {
                // Create new Translation object
                NSString *className = NSStringFromClass([Translation class]);
                NSString *entityName = nil;
                for ( NSEntityDescription *entity in self.managedObjectModel.entities ) {
                    if ( [entity.managedObjectClassName isEqualToString:className] ) {
                        entityName = entity.name;
                        break;
                    }
                }
                translation = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedObjectContext];
                translation.languageID = currentLangID;
                [stringToChange addTranslationsObject:translation];
            }
            
            translation.value = newString;
            
            NSError *error;
            [self.managedObjectContext save:&error];
            if ( error ) {
                NSLog(@"Failed to save localized string with error: %@", error);
            }
        }
        
    }
}

#pragma mark - Core Data
// Much of this code shamelessly copied from RZVinyl ( https://github.com/Raizlabs/RZVinyl )

static NSString *const kCRZManagedObjectModelName = @"CtrlZ";

- (NSURL *)storeURL
{
    if (_storeURL == nil) {
        if ( [self.storeType isEqualToString:NSSQLiteStoreType] ) {
            NSString *storeFileName = [kCRZManagedObjectModelName stringByAppendingPathExtension:@"sqlite"];
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
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:kCRZManagedObjectModelName withExtension:@"momd"]];
        if ( self.managedObjectModel == nil ) {
            NSLog(@"Could not create managed object model for name %@", kCRZManagedObjectModelName);
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
