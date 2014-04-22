//
//  EUCAnalyzeViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *const start_date_const = @"START_DATE";

@interface EUCAnalyzeViewController : UIViewController {
    NSDateFormatter *dateformat;
}
@property(weak, nonatomic) IBOutlet UILabel *errorLabel;
@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property(weak, nonatomic) IBOutlet UIView *contentView;
@property(weak, nonatomic) IBOutlet UIButton *startDateButton;
@property(weak, nonatomic) IBOutlet UIButton *endDateButton;

- (IBAction)showStartDatePicker:(id)sender;

- (IBAction)showEndDatePicker:(id)sender;

@end
