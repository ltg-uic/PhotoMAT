//
//  EUCImportCell.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImportCell.h"

@interface EUCImportCell () {}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;



@end

@implementation EUCImportCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
