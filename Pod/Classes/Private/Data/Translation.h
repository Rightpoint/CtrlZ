//
//  Translation.h
//  Changeable Test
//
//  Created by Spencer Poff on 2/6/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocalizedString;

@interface Translation : NSManagedObject

@property (nonatomic, retain) NSString * languageID;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) LocalizedString *localizedString;

@end
