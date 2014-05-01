//
// Created by Anthony Perritano on 4/9/14.
// Copyright (c) 2014 University of Illinois at Chicago. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TimelineView : UIView {

}

@property(nonatomic) NSMutableArray *bursts;
@property(nonatomic) int selectedBurstIndex;
@property(nonatomic) NSDate *startDate;
@property(nonatomic) NSDate *endDate;

@property(nonatomic, strong) NSDate *bandStartTime;

@property(nonatomic, strong) NSDate *bandEndTime;

- (NSString *)getDateForTouchPointXY:(CGPoint)point withStartDate:(NSDate *)startDate;
@end