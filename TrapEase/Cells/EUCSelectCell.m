//
//  EUCSelectCell.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCSelectCell.h"
#import "EUCSelectViewController.h"

@interface EUCSelectCell ()
{}

@end


@implementation EUCSelectCell
- (IBAction)toggle:(id)sender {
    [self.parentViewController toggleCell:self atIndexPath:self.indexPath];
}

@end
