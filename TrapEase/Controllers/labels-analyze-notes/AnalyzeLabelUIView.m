//
//  AnalyzeLabelUIView.m
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeLabelUIView.h"
#import "EUCBurst.h"

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

    for (EUCBurst *b in sortedBurts) {
        NSLog(@"Sorted burts %@", b.date);
    }


    _timeliveView.bursts = sortedBurts;
    _timeliveView.startDate = startDate;
    _timeliveView.endDate = endDate;

    _countLabel.text = [NSString stringWithFormat:@"%d", analyzeItem.labelCount];

    [self setNeedsDisplay];

}

@end
