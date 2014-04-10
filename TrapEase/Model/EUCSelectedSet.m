//
//  EUCSelectedSet.m
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/10/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCSelectedSet.h"

static EUCSelectedSet * selectedSet;

@implementation EUCSelectedSet


+(EUCSelectedSet *) sharedInstance {
    if (selectedSet == nil) {
        selectedSet = [[EUCSelectedSet alloc] init];
    }
    return selectedSet;
}

-(EUCSelectedSet *) init {
    if (self = [super init]) {
    }
    return self;
}

@end
