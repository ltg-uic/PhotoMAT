//
//  EUCAsset.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImage.h"

@implementation EUCImage


- (instancetype)initWithIndex: (NSInteger) index andUrl: (NSURL *) url
{
    self = [super init];
    if (self) {
        _index = index;
        _url = url;
    }
    return self;
}

- (instancetype)initWithIndex: (NSInteger) index andAsset: (ALAsset *) asset {
    self = [super init];
    if (self) {
        _index = index;
        _url = [asset valueForProperty:ALAssetPropertyAssetURL];
        _assetDate = [asset valueForProperty:ALAssetPropertyDate];
        _dimensions = asset.defaultRepresentation.dimensions;
    }
    return self;
}

@end
