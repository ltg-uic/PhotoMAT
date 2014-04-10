//
//  PopoverTagContentViewController.h
//  TrapEase
//
//  Created by Anthony Perritano on 4/6/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//



@interface PopoverTagContentViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *deleteLabel;
@property (nonatomic, copy) void (^deleteTagHandler)();


@property(nonatomic, strong) UIPopoverController *popoverController;

- (IBAction)deleteNO:(id)sender;
- (IBAction)deleteYES:(id)sender;

@end
