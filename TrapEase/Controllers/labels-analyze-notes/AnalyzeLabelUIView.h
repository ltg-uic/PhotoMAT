//
//  AnalyzeLabelUIView.h
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//


#import "TagView.h"
#import "TimelineView.h"
#import "AnalyzeItem.h"

@interface AnalyzeLabelUIView : UIView {

}
@property(weak, nonatomic) IBOutlet TagView *tagView;
@property(weak, nonatomic) IBOutlet TimelineView *timeliveView;
@property(weak, nonatomic) IBOutlet UILabel *countLabel;
@property(weak, nonatomic) IBOutlet TagView *labelTagView;


- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate withEndDate:(NSDate *)endDate withStartPeriod:(NSDate *)startPeriodDate withEndPeriod:(NSDate *)endPeriodDate;
@end
