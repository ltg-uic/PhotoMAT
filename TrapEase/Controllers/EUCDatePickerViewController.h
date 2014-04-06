//
//  EUCDatePickerViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 4/6/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EUCDatePickerDelegate <NSObject>

-(void) dateChangedTo: (NSDate *) date;

@end

@interface EUCDatePickerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) id<EUCDatePickerDelegate> delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil date: (NSDate *) date;

@end
