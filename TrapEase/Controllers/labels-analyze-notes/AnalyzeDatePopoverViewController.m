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

@implementation AnalyzeDatePopoverViewController {
    NSDateFormatter *dateformat;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    dateformat = [[NSDateFormatter alloc] init];
    [dateformat setDateFormat:@"hh:mm a M/d/Y"];
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
