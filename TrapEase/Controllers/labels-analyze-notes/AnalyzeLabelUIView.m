//
//  AnalyzeLabelUIView.m
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeLabelUIView.h"
#import "AnalyzeItem.h"

@implementation AnalyzeLabelUIView

-(id)init {
    AnalyzeLabelUIView *customView = [[[NSBundle mainBundle] loadNibNamed:@"AnalyzeLabelUIView" owner:self options:nil] lastObject];
    return customView;
}

- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {


    NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];

    NSArray *descriptors = [NSArray arrayWithObject:valueDescriptor];
    NSArray *sortedBurts = [analyzeItem.bursts sortedArrayUsingDescriptors:descriptors];

    analyzeItem.bursts = sortedBurts;

    _tagView.text = analyzeItem.labelName;

    _timeliveView.bursts = sortedBurts;
    _timeliveView.startDate = startDate;
    _timeliveView.endDate = endDate;

    _countLabel.text = [NSString stringWithFormat:@"%d", analyzeItem.bursts.count];

    [self setNeedsDisplay];

}

@end
