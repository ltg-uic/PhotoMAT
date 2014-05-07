//
//  AnalyzeDatePopoverViewController.m
//  PhotoMat
//
//  Created by Anthony Perritano on 4/21/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "AnalyzeDatePopoverViewController.h"

@interface AnalyzeDatePopoverViewController () {
}

@end

@implementation AnalyzeDatePopoverViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _dateformat = [[NSDateFormatter alloc] init];
        [_dateformat setDateFormat:@"hh:mm a M/d/Y"];


    }
    return self;
}

- (void)datePickerDateChanged:(id)datePickerDateChanged {
    if (_isNextDay) {
        if (_startPeriodDate != nil ) {
            NSDate *adjustedEndPeriod = [_datePicker.date dateByAddingTimeInterval:SECONDS_IN_DAY];
            NSDate *adjustedStartPeriod = [_startPeriodDate dateByAddingTimeInterval:SECONDS_IN_DAY];

            NSTimeInterval dif = [adjustedEndPeriod timeIntervalSinceDate:_startPeriodDate];

            if (dif > SECONDS_IN_DAY) {
                _datePicker.date = _startPeriodDate;
            }
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [_datePicker addTarget:self
                    action:@selector(datePickerDateChanged:)
          forControlEvents:UIControlEventValueChanged];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectedDate:(id)sender {

    _finishedHandler(_datePicker.date);
    [_somePopoverController dismissPopoverAnimated:true];


}

- (IBAction)cancelButton:(id)sender {
    [_somePopoverController dismissPopoverAnimated:true];
}

- (IBAction)resetButton:(id)sender {
    _datePicker.date = _orginalDate;
}
@end
