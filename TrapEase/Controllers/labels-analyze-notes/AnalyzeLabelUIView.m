//
//  AnalyzeLabelUIView.m
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeLabelUIView.h"
#import "EUCBurst.h"
#import "EUCDatabase.h"

@implementation AnalyzeLabelUIView

- (id)init {
    AnalyzeLabelUIView *customView = [[[NSBundle mainBundle] loadNibNamed:@"AnalyzeLabelUIView" owner:self options:nil] lastObject];
    return customView;
}

- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate withEndDate:(NSDate *)endDate withStartPeriod:(NSDate *)startPeriodDate withEndPeriod:(NSDate *)endPeriodDate {


    NSArray *sortedBurts = [analyzeItem sortedBurstsByDate];

    // _tagView.frame
    _tagView.text = analyzeItem.labelName;

    NSMutableArray *burstsInRange = [[NSMutableArray alloc] init];
    NSDate *startTime;
    NSDate *endTime;

    NSCalendar *calendar = [NSCalendar currentCalendar];

    //dummy filter

    NSDateComponents *startPeriodComps = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:startPeriodDate];

    NSDateComponents *endPeriodComps = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:endPeriodDate];


    NSTimeInterval timeDifference = [endPeriodDate timeIntervalSinceDate:startPeriodDate];


    for (EUCBurst *burst in sortedBurts) {
        // burst.date is before endDate (NSOrderedAscending)
        // burst.date is after startDate (NSOrderedDescending)
        if (([burst.date timeIntervalSince1970] >= [startDate timeIntervalSince1970]) && ([burst.date timeIntervalSince1970] <= [endDate timeIntervalSince1970])) {
            NSLog(@"burstsInRange: %@", burst.date);

            NSDateComponents *dateComponents = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:burst.date];

            //init

            //new starttime
            NSDateComponents *tempStartComps = [[NSDateComponents alloc] init];
            [tempStartComps setYear:dateComponents.year];
            [tempStartComps setMonth:dateComponents.month];
            [tempStartComps setDay:dateComponents.day];
            [tempStartComps setHour:startPeriodComps.hour];
            [tempStartComps setMinute:startPeriodComps.minute];
            [tempStartComps setSecond:startPeriodComps.second];

            NSDate *tempStartDate = [calendar dateFromComponents:tempStartComps];

            //new enddate

            NSDate *tempEndDate = [tempStartDate dateByAddingTimeInterval:timeDifference];



            //check if time of day
            if (([burst.date timeIntervalSince1970] >= [tempStartDate timeIntervalSince1970]) && ([burst.date timeIntervalSince1970] <= [tempEndDate timeIntervalSince1970])) {
                [burstsInRange addObject:burst];
            }

        }
    }

    int newLabelCount = 0;
    if (burstsInRange.count > 0) {

        for (EUCBurst *burst in burstsInRange) {
            NSArray *labels = [[EUCDatabase sharedInstance] labelsForBurst:burst.burstId];
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", analyzeItem.labelName];
            NSArray *foundObjs = [labels filteredArrayUsingPredicate:pred];
            if (foundObjs != nil && foundObjs.count >= 0) {
                newLabelCount = newLabelCount + foundObjs.count;
            }
        }
    }

    _timeliveView.bursts = burstsInRange;
    _timeliveView.startDate = startDate;
    _timeliveView.endDate = endDate;
    _timeliveView.bandStartTime = startPeriodDate;
    _timeliveView.bandEndTime = endPeriodDate;

    _countLabel.text = [NSString stringWithFormat:@"%d", newLabelCount];

    [self setNeedsDisplay];

}

@end
