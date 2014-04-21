//
//  AnalyzeItemUIView.m
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeItemUIView.h"
#import "AnalyzeItem.h"

@interface AnalyzeItemUIView () {
    
   
}


@property(weak, nonatomic) IBOutlet TagView *tagView;
@property(weak, nonatomic) IBOutlet UILabel *countLabel;
@property(weak, nonatomic) IBOutlet TimelineView *timelineView;

@end


@implementation AnalyzeItemUIView




- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {


    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];

    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
    NSArray *sortedBurts = [analyzeItem.bursts sortedArrayUsingDescriptors:descriptors];

    analyzeItem.bursts = sortedBurts;

    _timelineView.bursts = sortedBurts;
    _timelineView.startDate = startDate;
    _timelineView.endDate = endDate;
    [_timelineView setNeedsDisplay];

    //_countLabel.text = [NSString stringWithFormat:@"%d", analyzeItem.bursts.count];


}

@end
