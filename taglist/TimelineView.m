//
// Created by Anthony Perritano on 4/9/14.
// Copyright (c) 2014 University of Illinois at Chicago. All rights reserved.
//

#import "TimelineView.h"


@implementation TimelineView {

}

//called when defined in interface builder
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    UIView *
    [[NSBundle mainBundle] loadNibNamed:@"WidgetView" owner:self options:nil];
//    [self addSubview:self.view];
//
//    // The new self.view needs autolayout constraints for sizing
//    self.view.translatesAutoresizingMaskIntoConstraints = NO;
//    // Horizontal  200 in width
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_view(200)]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_view, self)]];
//    // Vertical   100 in height
//    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_view(100)]|" options:NSLayoutFormatDirectionLeadingToTrailing metrics:nil views:NSDictionaryOfVariableBindings(_view, self)]];

}


- (void)drawRect:(CGRect)rect {

    //draw the line

    //set in the middle of the views height
    CGFloat ypos = self.frame.size.height / 2.0;

    //the starting point
    CGFloat xposStart = 10.0;
    //the ending point
    CGFloat xposEnd = self.frame.size.width - xposStart;

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(xposStart, ypos)];
    [bezierPath addLineToPoint:CGPointMake(xposEnd, ypos)];
    bezierPath.lineCapStyle = kCGLineCapRound;

    [[UIColor blackColor] setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];

    //CGFloat circleRadius = 25;
    //[self drawRectOpenCircle:CGRectMake(33.5, ypos-5-circleRadius, circleRadius, circleRadius)];
    //[self drawPolaroidAtPoint:CGPointMake(60.0, ypos-5)];


}

- (void)drawPolaroidAtPoint:(CGPoint)tickPoint {

    CGFloat polaroidWidth = 26;
    CGFloat polaroidHeight = 25;


    CGFloat cornerX = tickPoint.x - (polaroidWidth / 2.0);
    CGFloat cornerY = 15;

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

- (void)drawRectOpenCircle:(CGRect)rect {
    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [[UIColor blackColor] setStroke];
    ovalPath.lineWidth = 3;
    [ovalPath stroke];


}
@end