//
//  EUCBurst.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCBurst.h"

@implementation EUCBurst

- (instancetype)init
{
    self = [super init];
    if (self) {
        _images = [[NSMutableArray alloc] initWithCapacity:6];
    }
    return self;
}
@end
