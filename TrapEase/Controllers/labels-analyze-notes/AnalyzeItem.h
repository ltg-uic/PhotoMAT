//
// Created by Anthony Perritano on 4/20/14.
// Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EUCBurst;


@interface AnalyzeItem : NSObject {

}

@property(nonatomic) int labelCount;
@property(nonatomic, strong) NSString *labelName;


- (void)addBurst:(EUCBurst *)burst;

- (NSArray *)sortedBurstsByDate;
@end