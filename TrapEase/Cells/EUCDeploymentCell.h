//
//  EUCDeploymentCell.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EUCDeploymentCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIButton *button;
- (IBAction)toggleSelected:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *school;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (assign, nonatomic) BOOL included;
@end
