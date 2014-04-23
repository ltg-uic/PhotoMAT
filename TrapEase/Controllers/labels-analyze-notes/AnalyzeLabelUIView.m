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

- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {


    NSArray *sortedBurts = [analyzeItem sortedBurstsByDate];

    // _tagView.frame
    _tagView.text = analyzeItem.labelName;

    //for(So)

//    for (EUCBurst *b in sortedBurts) {
//        NSLog(@"Sorted burts %@", b.date);
//    }
//
    NSMutableArray *burstsInRange = [[NSMutableArray alloc] init];

    for (EUCBurst *burst in sortedBurts) {
        // burst.date is before endDate (NSOrderedAscending)
        // burst.date is after startDate (NSOrderedDescending)
        if (([burst.date timeIntervalSince1970] >= [startDate timeIntervalSince1970]) && ([burst.date timeIntervalSince1970] <= [endDate timeIntervalSince1970])) {
            NSLog(@"burstsInRange: %@", burst.date);
            [burstsInRange addObject:burst];
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

    _timeliveView.bursts = sortedBurts;
    _timeliveView.startDate = startDate;
    _timeliveView.endDate = endDate;

    _countLabel.text = [NSString stringWithFormat:@"%d", newLabelCount];

    [self setNeedsDisplay];

}

@end
