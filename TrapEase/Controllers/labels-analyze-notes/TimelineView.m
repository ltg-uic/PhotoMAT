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

}

- (void)drawLineWithStartDate:(NSDate *)sDate andEndDate:(NSDate *)eDate andXStart:(CGFloat)xStart withColor:(UIColor *)lineColor {
    //init

    xposStart = xStart;

    //set in the middle of the views height

    ypos = self.frame.size.height / 2.0;

    //the starting point


    //the ending point
    xposEnd = self.frame.size.width - xposStart;


    //get the total time
    totalTime = [sDate timeIntervalSinceDate:eDate];

    lineLength = xposEnd - xposStart;

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(xposStart, ypos)];
    [bezierPath addLineToPoint:CGPointMake(xposEnd, ypos)];
    bezierPath.lineCapStyle = kCGLineCapRound;

    [lineColor setStroke];
    bezierPath.lineWidth = 3;
    [bezierPath stroke];
}

- (void)drawRect:(CGRect)rect {

    if (_startDate != nil && _endDate != nil ) {
        [self drawLineWithStartDate:_startDate andEndDate:_endDate andXStart:12 withColor:[UIColor colorWithRed:184.0f / 255.0f green:184.0f / 255.0f blue:184.0f / 255.0f alpha:.5]];


        NSString *firstTextLabel = [dateformat stringFromDate:_startDate];
        NSString *lastTextLabel = [dateformat stringFromDate:_endDate];

        // [self drawCircleTickMarkAtPoint:firstTextLabel atPoint:CGPointMake(xposStart, ypos) isHighlighted:NO hasBeenVisited:YES showLabel:NO];


        for (int j = 0; j < _bursts.count; j++) {
            EUCBurst *b = _bursts[j];
            CGFloat tickOffset = xposStart + ([_startDate timeIntervalSinceDate:b.date] / (totalTime)) * lineLength;
            NSString *formatedLabel = [dateformat stringFromDate:b.date];

            [self drawCircleTickMarkAtPoint:formatedLabel atPoint:CGPointMake(tickOffset, ypos) isHighlighted:NO hasBeenVisited:YES showLabel:NO];


        }
        //[self drawCircleTickMarkAtPoint:lastTextLabel atPoint:CGPointMake(xposEnd, ypos) isHighlighted:NO hasBeenVisited:YES showLabel:NO];

        //drawing


        //loop #days


        if (![_bandStartTime isEqualToDate:_bandEndTime]) {

            int daysBetweenStartAndEnd = [self daysBetween:_startDate and:_endDate];

            for (int j = 0; j <= daysBetweenStartAndEnd; j++) {


                // 86400 seconds in a day * j (which day)
                int dayOffset = (86400) * j;

                NSDate *periodStartTime = [self combineTimeFromDate:_bandStartTime andDayMonthYearFromDate:_startDate];

                periodStartTime = [periodStartTime dateByAddingTimeInterval:dayOffset];


                CGFloat startOffset = xposStart + ([_startDate timeIntervalSinceDate:periodStartTime] / (totalTime)) * lineLength;

                NSString *formatedLabel = [dateformat stringFromDate:periodStartTime];

                //[self drawCircleTickMarkAtPoint:formatedLabel atPoint:CGPointMake(startOffset, ypos) isHighlighted:NO hasBeenVisited:YES showLabel:YES];

                //draw the end point
                NSTimeInterval timeDifference = [_bandEndTime timeIntervalSinceDate:_bandStartTime];

                NSDate *periodEndTime = [periodStartTime dateByAddingTimeInterval:timeDifference];

                CGFloat endOffset = xposStart + ([_startDate timeIntervalSinceDate:periodEndTime] / (totalTime)) * lineLength;

                formatedLabel = [dateformat stringFromDate:periodEndTime];

                //[self drawCircleTickMarkAtPoint:formatedLabel atPoint:CGPointMake(endOffset, ypos) isHighlighted:NO hasBeenVisited:YES showLabel:YES];

                [self drawLineAtPoint:CGPointMake(startOffset, ypos) atPoint:CGPointMake(endOffset, ypos) withColor:[UIColor blackColor]];
            }

        }


    } else if (_bursts != nil ) {



        //create end point labels
        EUCBurst *firstBurst = [_bursts firstObject];
        NSString *firstTextLabel = [dateformat stringFromDate:firstBurst.date];


        EUCBurst *lastBurst = [_bursts lastObject];
        NSString *lastTextLabel = [dateformat stringFromDate:lastBurst.date];

        [self drawLineWithStartDate:firstBurst.date andEndDate:lastBurst.date andXStart:(textWidth / 2.0f) withColor:NULL ];

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

- (void)drawLineAtPoint:(CGPoint)pointA atPoint:(CGPoint)pointB withColor:(UIColor *)lineColor {
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:pointA];
    [bezierPath addLineToPoint:pointB];
    bezierPath.lineCapStyle = kCGLineCapRound;

    [lineColor setStroke];
    bezierPath.lineWidth = 3;
    [bezierPath stroke];
}

- (NSDate *)combineTimeFromDate:(NSDate *)timeDate andDayMonthYearFromDate:(NSDate *)dayDate {

    NSDateComponents *timeDateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate:timeDate];

    NSDateComponents *dayDateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit
                                                                          fromDate:dayDate];

    NSDateComponents *newTimeDateComponents = [[NSDateComponents alloc] init];
    [newTimeDateComponents setYear:dayDateComponents.year];
    [newTimeDateComponents setMonth:dayDateComponents.month];
    [newTimeDateComponents setDay:dayDateComponents.day];
    [newTimeDateComponents setHour:timeDateComponents.hour];
    [newTimeDateComponents setMinute:timeDateComponents.minute];
    [newTimeDateComponents setSecond:timeDateComponents.second];

    NSDate *newDate = [[NSCalendar currentCalendar] dateFromComponents:newTimeDateComponents];

    return newDate;
}

- (NSInteger)daysBetween:(NSDate *)date1 and:(NSDate *)date2 {
    unsigned int unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit | NSYearCalendarUnit;
    NSDateComponents *compsDate1 = [[NSCalendar currentCalendar] components:unitFlags fromDate:date1];
    NSDateComponents *compsDate2 = [[NSCalendar currentCalendar] components:unitFlags fromDate:date2];

    //same day
    if ((compsDate1.month == compsDate2.month) && (compsDate1.day == compsDate2.day)) {
        return 0;
    } else if ((compsDate1.month == compsDate2.month)) {
        return abs(compsDate1.day - compsDate2.day);
    } else {

        NSDate *fromDate;
        NSDate *toDate;

        NSCalendar *calendar = [NSCalendar currentCalendar];

        [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                     interval:NULL forDate:date1];
        [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                     interval:NULL forDate:date2];

        NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                                   fromDate:fromDate toDate:toDate options:0];

        return [difference day];
    }

    return 0;
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
    int haloOffsetRadius = circleRadius + 4;

    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - (circleRadius / 2), point.y - (circleRadius / 2), circleRadius, circleRadius)];
    [[UIColor lightGrayColor] setStroke];

    if (isHighlighted) {

        [[UIColor blueColor] setFill];

        UIBezierPath *ovalPath2 = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - (haloOffsetRadius / 2), point.y - (haloOffsetRadius / 2), haloOffsetRadius, haloOffsetRadius)];
        ovalPath2.lineWidth = 1;
        [[UIColor colorWithRed:0.343 green:0.781 blue:1 alpha:1] setStroke];
        [ovalPath2 stroke];


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

- (NSString *)getDateForTouchPointXY:(CGPoint)point withStartDate:(NSDate *)startDate {

//    clickX = x-coordinate of the location you touch (ignore y)
//    selectedTime = startingTime + (clickX-PixelL) / lineLength * totalTime
//    popover (selectedTime)


    NSTimeInterval selectedTime = [startDate timeIntervalSince1970] + ((point.x - xposStart) / lineLength) * abs(totalTime);


    NSDate *date = [NSDate dateWithTimeIntervalSince1970:selectedTime];

    NSString *formattedDateString = [dateformat stringFromDate:date];
    return formattedDateString;

}
@end
