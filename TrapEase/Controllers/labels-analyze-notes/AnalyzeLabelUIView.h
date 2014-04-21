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
@property (weak, nonatomic) IBOutlet TagView *tagView;
@property (weak, nonatomic) IBOutlet TimelineView *timeliveView;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;
@end
