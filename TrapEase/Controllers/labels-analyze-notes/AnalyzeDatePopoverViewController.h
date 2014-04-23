//
//  AnalyzeDatePopoverViewController.h
//  PhotoMat
//
//  Created by Anthony Perritano on 4/21/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AnalyzeDatePopoverViewController : UIViewController

@property(weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property(weak, nonatomic) IBOutlet UIButton *selectButton;


@property(nonatomic, strong) UIPopoverController *somePopoverController;

@property(nonatomic, copy) void (^finishedHandler)(NSDate *);

@property(nonatomic, strong) NSDate *orginalDate;

- (IBAction)selectedDate:(id)sender;

@end
