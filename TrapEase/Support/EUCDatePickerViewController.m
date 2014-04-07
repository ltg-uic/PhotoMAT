//
//  EUCDatePickerViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 4/6/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDatePickerViewController.h"

@interface EUCDatePickerViewController ()
{ }
@property (strong, nonatomic) NSDate *date;

@end

@implementation EUCDatePickerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.preferredContentSize = CGSizeMake(320, 216);
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil date: (NSDate *) date
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.preferredContentSize = CGSizeMake(320, 216);
        self.date = date;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (self.date) {
        self.datePicker.date = self.date;
    }
    [self.delegate dateChangedTo:self.datePicker.date];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dateValueChanged:(id)sender {
    [self.delegate dateChangedTo:self.datePicker.date];
}

@end
