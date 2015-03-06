//
//  Translation.m
//  Changeable Test
//
//  Created by Spencer Poff on 2/6/15.
//  Copyright (c) 2015 Spencer Poff. All rights reserved.
//

#import "Translation.h"
#import "LocalizedString.h"


@implementation Translation

@dynamic languageID;
@dynamic value;
@dynamic dateModified;
@dynamic localizedString;

- (void)awakeFromInsert
{
    self.dateModified = [NSDate date];
}

@end
