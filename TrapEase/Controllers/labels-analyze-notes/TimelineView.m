//
// Created by Anthony Perritano on 4/9/14.
// Copyright (c) 2014 University of Illinois at Chicago. All rights reserved.
//

#import "TimelineView.h"
#import "EUCBurst.h"


@implementation TimelineView {
    NSDateFormatter *dateformat;
    CGFloat ypos;
    CGFloat lineLength;
    CGFloat xposStart;
    CGFloat xposEnd;


    NSTimeInterval totalTime;
}

int textWidth = 80;


//called when defined in interface builder
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setup];

}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {

    dateformat = [[NSDateFormatter alloc] init];
    [dateformat setDateFormat:@"hh:mm:ss a M/d/Y"];
//    [dateformat setAMSymbol:@"am"];
//    [dateformat setPMSymbol:@"pm"];



}

- (void)drawLineWithStartDate:(NSDate *)sDate andEndDate:(NSDate *)eDate {
    //init

    //set in the middle of the views height

    ypos = self.frame.size.height / 2.0;

    //the starting point
    xposStart = textWidth / 2;
    //the ending point
    xposEnd = self.frame.size.width - xposStart;


    //get the total time
    totalTime = [sDate timeIntervalSinceDate:eDate];

    lineLength = xposEnd - xposStart;

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(xposStart, ypos)];
    [bezierPath addLineToPoint:CGPointMake(xposEnd, ypos)];
    bezierPath.lineCapStyle = kCGLineCapRound;

    [[UIColor blackColor] setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];
}

- (void)drawRect:(CGRect)rect {

    if (_startDate != nil && _endDate != nil ) {
        [self drawLineWithStartDate:_startDate andEndDate:_endDate];


        NSString *firstTextLabel = [dateformat stringFromDate:_startDate];
        NSString *lastTextLabel = [dateformat stringFromDate:_endDate];

        [self drawCircleTickMarkAtPoint:firstTextLabel atPoint:CGPointMake(xposStart, ypos) isHighlighted:YES hasBeenVisited:YES showLabel:YES];


        for (int j = 1; j < _bursts.count; j++) {
            EUCBurst *b = _bursts[j];
            CGFloat tickOffset = xposStart + ([_startDate timeIntervalSinceDate:b.date] / (totalTime)) * lineLength;
            NSString *formatedLabel = [dateformat stringFromDate:b.date];

            BOOL showLabel = NO;
            if (j == _bursts.count - 1) {
                showLabel = YES;
            }
            [self drawCircleTickMarkAtPoint:formatedLabel atPoint:CGPointMake(tickOffset, ypos) isHighlighted:b.highlighted hasBeenVisited:b.hasBeenVisited showLabel:showLabel];


        }
    } else if (_bursts != nil ) {



        //create end point labels
        EUCBurst *firstBurst = _bursts[0];
        NSString *firstTextLabel = [dateformat stringFromDate:firstBurst.date];


        EUCBurst *lastBurst = _bursts[_bursts.count - 1];
        NSString *lastTextLabel = [dateformat stringFromDate:lastBurst.date];

        [self drawLineWithStartDate:firstBurst.date andEndDate:lastBurst.date];

        [self drawCircleTickMarkAtPoint:firstTextLabel atPoint:CGPointMake(xposStart, ypos) isHighlighted:firstBurst.highlighted hasBeenVisited:firstBurst.hasBeenVisited showLabel:YES];


        for (int j = 1; j < _bursts.count; j++) {
            EUCBurst *b = _bursts[j];
            CGFloat tickOffset = xposStart + ([firstBurst.date timeIntervalSinceDate:b.date] / (totalTime)) * lineLength;
            NSString *formatedLabel = [dateformat stringFromDate:b.date];

            BOOL showLabel = NO;
            if (j == _bursts.count - 1) {
                showLabel = YES;
            }
            [self drawCircleTickMarkAtPoint:formatedLabel atPoint:CGPointMake(tickOffset, ypos) isHighlighted:b.highlighted hasBeenVisited:b.hasBeenVisited showLabel:showLabel];


        }

    }
}


- (void)drawRectOpenCircle:(CGRect)rect {
    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    [[UIColor blackColor] setStroke];
    ovalPath.lineWidth = 3;
    [ovalPath stroke];
}

- (void)drawTickMark:(CGPoint)point {

    int offset = 10;
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(point.x, point.y - offset)];
    [bezierPath addLineToPoint:CGPointMake(point.x, point.y)];
    [[UIColor blackColor] setStroke];
    bezierPath.lineWidth = 2;
    [bezierPath stroke];

}

- (void)drawCircleTickMarkAtPoint:(NSString *)text atPoint:(CGPoint)point isHighlighted:(BOOL)isHighlighted hasBeenVisited:(BOOL)hasBeenVisited showLabel:(BOOL)hasLabel {

    int offset = 10;
    CGFloat circleRadius = 20;

    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - (circleRadius / 2), point.y - (circleRadius / 2), circleRadius, circleRadius)];
    [[UIColor lightGrayColor] setStroke];

    if (isHighlighted) {
        [[UIColor blueColor] setFill];
    } else {
        if (hasBeenVisited) {
            [[UIColor blackColor] setFill];

        } else {
            [[UIColor whiteColor] setFill];
        }
    }


    ovalPath.lineWidth = 1;
    [ovalPath stroke];
    [ovalPath fill];



    //[self drawTickMark:point];
    if (hasLabel)
        [self drawTickLabel:text atPoint:CGPointMake(point.x, point.y + offset)];

}


- (void)drawEndPointTickMarkAtPoint:(NSString *)text atPoint:(CGPoint)point {

    int offset = 10;
    [self drawTickMark:point];
    [self drawTickLabel:text atPoint:CGPointMake(point.x, point.y + offset)];

}

- (void)drawTickLabel:(NSString *)text atPoint:(CGPoint)point {

    int textHeight = 30;
    CGRect textRect = CGRectMake(point.x - (textWidth / 2), point.y, textWidth, textHeight);

    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment:NSTextAlignmentCenter];

    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    NSDictionary *textFontAttributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : [UIColor blackColor], NSBackgroundColorAttributeName : [UIColor clearColor], NSParagraphStyleAttributeName : textStyle};


    [text drawInRect:textRect withAttributes:textFontAttributes];

}

@end
