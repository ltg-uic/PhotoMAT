//
// Created by Anthony Perritano on 4/9/14.
// Copyright (c) 2014 University of Illinois at Chicago. All rights reserved.
//

#import "TimelineView.h"
#import "EUCBurst.h"


int textWidth = 52;

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

        [self drawEndPointTickMarkAtPoint:firstTextLabel atPoint:CGPointMake(xposStart, ypos)];

        for (int j = 1; j < _bursts.count; j++) {
            EUCBurst *b = _bursts[j];
            CGFloat tickOffset = xposStart + ([firstBurst.date timeIntervalSinceDate:b.date]/(totalTime*lineLength));
            NSString *formatedLabel = [dateformat stringFromDate:b.date];
            [self drawEndPointTickMarkAtPoint:formatedLabel atPoint:CGPointMake(tickOffset, ypos)];


        }


        //CGFloat circleRadius = 25;
        //[self drawRectOpenCircle:CGRectMake(33.5, ypos-5-circleRadius, circleRadius, circleRadius)];
        //[self drawPolaroidAtPoint:CGPointMake(60.0, ypos-5)];
        [self drawEndPointTickMarkAtPoint:firstTextLabel atPoint:CGPointMake(xposStart, ypos)];
        //[self drawEndPointTickMarkAtPoint:lastTextLabel atPoint:CGPointMake(xposEnd, ypos)];

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
    [bezierPath addLineToPoint:CGPointMake(point.x, point.y + offset)];
    [[UIColor blackColor] setStroke];
    bezierPath.lineWidth = 2;
    [bezierPath stroke];

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
    innerRectangle.lineWidth = 2;
    [innerRectangle stroke];
}
@end
