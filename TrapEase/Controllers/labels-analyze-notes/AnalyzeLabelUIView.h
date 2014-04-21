//
//  AnalyzeLabelUIView.h
//  TrapEase
//
//  Created by Anthony Perritano on 4/20/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//


#import "TagView.h"
#import "TimelineView.h"
@interface AnalyzeLabelUIView : UIView
@property (weak, nonatomic) IBOutlet TagView *tagView;
@property (weak, nonatomic) IBOutlet TimelineView *timelineView;
@property (weak, nonatomic) IBOutlet UILabel *tagCountLabel;

@end
