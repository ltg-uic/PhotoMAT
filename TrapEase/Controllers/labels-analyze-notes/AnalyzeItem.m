//
// Created by Anthony Perritano on 4/20/14.
// Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeItem.h"
#import "EUCBurst.h"

@interface AnalyzeItem () {
    NSMutableArray *bursts;
}

@end

@implementation AnalyzeItem {

}
- (id)init {
    self = [super init];
    if (self) {

    }

    return self;
}

-(void) addBurst:(EUCBurst *)burst {

    if (bursts == nil ) {
        bursts = [[NSMutableArray alloc] init];
        _labelCount = 0;
    }

    _labelCount++;

    if (![bursts containsObject:burst]) {

        [bursts addObject:burst];
    }
}

- (NSArray *)sortedBurstsByDate {
    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];

    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];

    return [bursts sortedArrayUsingDescriptors:descriptors];
}
@end