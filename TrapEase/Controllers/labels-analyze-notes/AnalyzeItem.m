//
// Created by Anthony Perritano on 4/20/14.
// Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeItem.h"
#import "EUCBurst.h"

@interface AnalyzeItem () {
    
}

@end

@implementation AnalyzeItem {

}

-(void) addBurst:(EUCBurst *)burst {

    _labelCount++;

    if( _bursts == nil ) {
         _bursts = [[NSMutableArray alloc] init];
    }
    if(![_bursts containsObject:burst]) {
        [_bursts addObject:burst];
    }
}
@end