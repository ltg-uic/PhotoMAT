//
// Created by Anthony Perritano on 4/9/14.
// Copyright (c) 2014 University of Illinois at Chicago. All rights reserved.
//

#import "TimelineView.h"
#import "EUCBurst.h"






@implementation TimelineView {

}

int textWidth = 52;


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
    //UIView *
    //[[NSBundle mainBundle] loadNibNamed:@"WidgetView" owner:self options:nil];
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

    if (_bursts != nil ) {

        NSDateFormatter *dateformat = [[NSDateFormatter alloc] init];
        [dateformat setDateFormat:@"hh:mm:ss M/d/Y"];

        //init

        //set in the middle of the views height
        CGFloat ypos = self.frame.size.height / 2.0;

        //the starting point
        CGFloat xposStart = textWidth / 2;
        //the ending point
        CGFloat xposEnd = self.frame.size.width - xposStart;

        //create end point labels
        EUCBurst *firstBurst = _bursts[0];

        NSString *firstTextLabel = [dateformat stringFromDate:firstBurst.date];


        EUCBurst *lastBurst = _bursts[_bursts.count - 1];
        NSString *lastTextLabel = [dateformat stringFromDate:lastBurst.date];

        //get the total time
        NSTimeInterval totalTime = [firstBurst.date timeIntervalSinceDate:lastBurst.date];
        CGFloat lineLength = xposEnd - xposStart;

        UIBezierPath *bezierPath = [UIBezierPath bezierPath];
        [bezierPath moveToPoint:CGPointMake(xposStart, ypos)];
        [bezierPath addLineToPoint:CGPointMake(xposEnd, ypos)];
        bezierPath.lineCapStyle = kCGLineCapRound;

        [[UIColor blackColor] setStroke];
        bezierPath.lineWidth = 1;
        [bezierPath stroke];

        [self drawCircleTickMarkAtPoint:firstTextLabel atPoint:CGPointMake(xposStart, ypos) isHighlighted:firstBurst.highlighted hasBeenVisited:firstBurst.hasBeenVisited showLabel:YES];

        
        
        for (int j = 1; j < _bursts.count; j++) {
            EUCBurst *b = _bursts[j];
            CGFloat tickOffset = xposStart + ([firstBurst.date timeIntervalSinceDate:b.date]/(totalTime))*lineLength;
            NSString *formatedLabel = [dateformat stringFromDate:b.date];

            BOOL showLabel = NO;
            if( j == _bursts.count-1 ){
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

    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x-(circleRadius/2), point.y-(circleRadius/2), circleRadius, circleRadius)];
    [[UIColor lightGrayColor] setStroke];

    if( isHighlighted ) {
        [[UIColor blueColor] setFill];
    } else {
        if(  hasBeenVisited ) {
            [[UIColor blackColor] setFill];

        } else {
            [[UIColor whiteColor] setFill];
        }
    }


    ovalPath.lineWidth = 1;
    [ovalPath stroke];
    [ovalPath fill];



    //[self drawTickMark:point];
    if( hasLabel )
        [self drawTickLabel:text atPoint:CGPointMake(point.x, point.y + offset)];

}


- (void)drawEndPointTickMarkAtPoint:(NSString *)text atPoint:(CGPoint)point {

    int offset = 10;
    [self drawTickMark:point];
    [self drawTickLabel:text atPoint:CGPointMake(point.x, point.y + offset)];

}

- (void)drawTickLabel:(NSString *)text atPoint:(CGPoint)point {

    int textHeight = 26;
    CGRect textRect = CGRectMake(point.x - (textWidth / 2), point.y, textWidth, textHeight);

    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment:NSTextAlignmentCenter];

    UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:10];
    NSDictionary *textFontAttributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : [UIColor blackColor], NSParagraphStyleAttributeName : textStyle};


    [text drawInRect:textRect withAttributes:textFontAttributes];

}

@end
