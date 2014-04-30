//
//  EUCDeploymentCell.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDeploymentCell.h"
#import "EUCDeploymentMasterViewController.h"

@interface EUCDeploymentCell ()

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@end


@implementation EUCDeploymentCell

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

- (IBAction)toggleSelected:(id)sender {
    BOOL selected = NO;
    if (self.master.selectedStatusBySetId[@(self.setId)] == nil) {
        self.master.selectedStatusBySetId[@(self.setId)] = @YES;
        selected = YES;
    }
    else if ([self.master.selectedStatusBySetId[@(self.setId)] isEqual:@(NO)]) {
        self.master.selectedStatusBySetId[@(self.setId)] = @YES;
        selected = YES;
    }
    else if ([self.master.selectedStatusBySetId[@(self.setId)] isEqual:@(YES)]) {
        self.master.selectedStatusBySetId[@(self.setId)] = @NO;
        selected = NO;
    }
    
    if (selected) {
        [self.selectButton setImage:[UIImage imageNamed:@"thumbs-up-selected"] forState:UIControlStateNormal];
    }
    else {
        [self.selectButton setImage:[UIImage imageNamed:@"thumbs-up"] forState:UIControlStateNormal];
    }
    
}


@end
