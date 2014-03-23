//
//  EUCSelectCell.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EUCSelectViewController;

@interface EUCSelectCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (assign, nonatomic) BOOL rejected;
@property (weak, nonatomic) IBOutlet UIView *mask;
@property (weak, nonatomic) EUCSelectViewController * parentViewController;
@property (strong, nonatomic) NSIndexPath *indexPath;

@end
