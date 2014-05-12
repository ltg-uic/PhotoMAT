//
//  CountPickerViewController.h
//  PhotoMat
//
//  Created by Anthony Perritano on 5/10/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CountPickerViewController : UIViewController

@property(nonatomic, strong) UIPopoverController *somePopoverController;
@property(nonatomic, copy) void (^finishedHandler)(NSString *);
@property(weak, nonatomic) IBOutlet UIPickerView *indexPicker;
@property(nonatomic, strong) NSMutableArray *burstIndexes;

- (void)selectRow:(int)selectedIndex;

- (IBAction)selectIndex:(id)sender;
@end
