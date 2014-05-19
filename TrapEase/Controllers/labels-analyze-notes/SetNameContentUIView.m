//
//  SetNameContentUIView.m
//  PhotoMat
//
//  Created by Anthony Perritano on 5/1/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "SetNameContentUIView.h"

@interface SetNameContentUIView ()

@end

@implementation SetNameContentUIView

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self loadContentsFromNib];

}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self loadContentsFromNib];
        //        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        //        self.layer.shadowOffset = CGSizeMake(1.0, 1.0);
        //        self.layer.shadowOpacity = 0.10;
    }
    return self;
}
@end
