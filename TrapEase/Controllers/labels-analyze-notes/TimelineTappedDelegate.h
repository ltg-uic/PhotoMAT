//
// Created by Anthony Perritano on 5/13/14.
// Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TimelineTappedDelegate <NSObject>

- (void)didSelectBurstIndexFromTap:(int)selectedBurstIndex;


@end