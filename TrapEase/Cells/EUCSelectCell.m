//
//  EUCSelectCell.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCSelectCell.h"

@interface EUCSelectCell ()
{}
@property (weak, nonatomic) IBOutlet UIView *mask;

@end


@implementation EUCSelectCell
- (IBAction)toggle:(id)sender {
    self.rejected = !(self.rejected);
    if (self.rejected) {
        self.mask.hidden = NO;
        [self.button setImage:[UIImage imageNamed:@"thumbs-down.png"] forState:UIControlStateNormal];
    }
    else {
        self.mask.hidden = YES;
        [self.button setImage:[UIImage imageNamed:@"thumbs-up.png"] forState:UIControlStateNormal];
    }
    [self.button setNeedsDisplay];
}

@end
