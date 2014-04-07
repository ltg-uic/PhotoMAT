//
//  EUCAsset.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImage.h"

@implementation EUCImage


- (instancetype)initWithIndex: (NSInteger) index andFilename: (NSString *) filename
{
    self = [super init];
    if (self) {
        _index = index;
        _filename = filename;
    }
    return self;
}

- (instancetype)initWithIndex: (NSInteger) index andUrl: (NSURL *) url
{
    self = [super init];
    if (self) {
        _index = index;
        _url = url;
    }
    return self;
}
@end
