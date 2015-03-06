//
//  LocalizedString.h
//  Changeable Test
//
//  Created by Spencer Poff on 1/25/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Translation;

@interface LocalizedString : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSSet *translations;
@end

@interface LocalizedString (CoreDataGeneratedAccessors)

- (void)addTranslationsObject:(Translation *)value;
- (void)removeTranslationsObject:(Translation *)value;
- (void)addTranslations:(NSSet *)values;
- (void)removeTranslations:(NSSet *)values;

@end
