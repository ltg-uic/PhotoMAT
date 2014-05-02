//
// Created by Anthony Perritano on 5/2/14.
// Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "TransparentPopoverBackGroundView.h"

#define DEFAULT_TINT_COLOR [UIColor clearColor];

@implementation TransparentPopoverBackGroundView {


}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0.1;
    }
    return self;
}

@end