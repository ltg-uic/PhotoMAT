//
//  TagView.m
//  ios_tag_list
//
//  Created by Maxim on 9/22/13.
//  Copyright (c) 2013 Maxim. All rights reserved.
//

#import "TagView.h"

#import <CoreText/CoreText.h>

static const CGFloat TagViewHighlightAlpha = 0.5;
static NSString *const TagViewFontFamily = @"Helvetica-Bold";
static const CGFloat TagViewFontSize = 15.0;
static const CGFloat TagViewFontSizeMin = 10.0;
static const int TagViewMaxCharacter = 20;
static const CGFloat TagViewCornerWidth = 5.0;
static const CGFloat TagViewCornerHeight = 5.0;

@implementation TagView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        state = TagViewStateNormal;

        //self.color = [UIColor yellowTagColor];
        //self.colorHightlighted = [UIColor yellowTagColor:TagViewHighlightAlpha];
        self.fontColor = [UIColor whiteColor];
        //self.fontColor = [UIColor colorWithRed:0.298 green:0.337 blue:0.424 alpha:1.000];
        self.text = @"Default";
        [self setBackgroundColor:[UIColor clearColor]];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame andText:(NSString *)text {
    self = [super initWithFrame:frame];
    if (self) {
        state = TagViewStateNormal;
        self.fontColor = [UIColor whiteColor];
        self.text = text;
        [self setBackgroundColor:[UIColor clearColor]];
    }

    return self;
}


- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);

    const BOOL reduce = (self.text.length > TagViewMaxCharacter);

    UIColor *color = nil;
    switch (state) {
        case TagViewStateNormal:
            color = self.color;
            break;

        case TagViewStateHighlighted:
            color = self.colorHightlighted;
            break;

        default:
            break;
    }

    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, rect);

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGMutablePathRef roundedRectPath = CGPathCreateMutable();
    CGPathAddRoundedRect(roundedRectPath, NULL, CGRectMake(0, 0, rect.size.width, rect.size.height), TagViewCornerWidth, TagViewCornerHeight);
    CGContextAddPath(context, roundedRectPath);
    CGContextFillPath(context);

    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef) TagViewFontFamily, (reduce ? TagViewFontSizeMin : TagViewFontSize), NULL);
    CGColorRef fontColorRef = self.fontColor.CGColor;
    if( fontColorRef == nil ) {
         fontColorRef = [[UIColor whiteColor] CGColor];
    }

    NSString *finalText = (!reduce ? self.text : [NSString stringWithFormat:@"%@...", [self.text substringToIndex:TagViewMaxCharacter]]);

    if(finalText == nil) {
        finalText = @"error?";
    }

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CTTextAlignment alignment = kCTTextAlignmentCenter;

    CTParagraphStyleSetting settings[] = {
            {kCTParagraphStyleSpecifierAlignment, sizeof(alignment), &alignment}
    };

    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings) / sizeof(settings[0]));

    CFStringRef keys[] = {kCTFontAttributeName, kCTParagraphStyleAttributeName, kCTForegroundColorAttributeName};
    CFTypeRef values[] = {font, paragraphStyle, fontColorRef};
    CFDictionaryRef attr = CFDictionaryCreate(NULL, (const void **) &keys, (const void **) &values, sizeof(keys) / sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks,
            &kCFTypeDictionaryValueCallBacks);



    CFAttributedStringRef attrString = CFAttributedStringCreate(NULL, (__bridge CFStringRef) finalText, attr);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) attrString);

    CGRect boundingBox = CTFontGetBoundingBox(font);

    const float midHeight = rect.size.height * 0.4f;
    const float midFontBBHeight = boundingBox.size.height * 0.5f;
    const float height = midHeight + midFontBBHeight;


    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, rect.size.width, height));

    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);

    CFRelease(attrString);
    CGPathRelease(roundedRectPath);
    CGPathRelease(path);
    CFRelease(framesetter);
    CFRelease(frame);
}

- (TagView *)copy {


    TagView *copyOfView =
            [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];

    copyOfView.text = _text.copy;
    copyOfView.color = self.color.copy;
    copyOfView.fontColor = self.fontColor.copy;
    copyOfView.colorHightlighted = self.colorHightlighted.copy;
    copyOfView.tag = self.tag;
    copyOfView.labelId = self.labelId;


    return copyOfView;
}

@end
