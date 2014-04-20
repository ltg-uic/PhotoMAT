//
//  TimelineItemSubView.m
//  PhotoMat
//
//  Created by Anthony Perritano on 4/10/14.
//  Copyright (c) 2014 University of Illinois at Chicago. All rights reserved.
//

#import "TimelineItemSubView.h"

@implementation TimelineItemSubView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGFloat polaroidWidth = 26;
    CGFloat polaroidHeight = 25;


    CGFloat cornerX = 0;
    CGFloat cornerY = 0;

    UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(cornerX, cornerY, polaroidWidth, polaroidHeight) cornerRadius:0];
    [[UIColor whiteColor] setFill];
    [roundedRectanglePath fill];
    [[UIColor blackColor] setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];

    UIBezierPath *innerRectangle = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(cornerX + 3, cornerY + 3, polaroidWidth - 6, polaroidHeight - 8) cornerRadius:0];
    [[UIColor lightGrayColor] setFill];
    [innerRectangle fill];
    [[UIColor blackColor] setStroke];
    innerRectangle.lineWidth = 1;
    [innerRectangle stroke];
}


@end
