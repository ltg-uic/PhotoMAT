//
//  AnalyzeItemUIView.h
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "TagView.h"
#import "TimelineView.h"

@class AnalyzeItem;

@interface AnalyzeItemUIView : UIView {

}

- (void)displayAnalyzeItem:(AnalyzeItem *)analyzeItem withStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;
@end
