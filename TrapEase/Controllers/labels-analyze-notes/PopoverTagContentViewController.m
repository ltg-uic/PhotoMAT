//
//  PopoverTagContentViewController.m
//  TrapEase
//
//  Created by Anthony Perritano on 4/6/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "PopoverTagContentViewController.h"

@interface PopoverTagContentViewController ()

@end

@implementation PopoverTagContentViewController {
    UIPopoverController *popoverController;

}

@synthesize popoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)deleteNO:(id)sender {
    [popoverController dismissPopoverAnimated:true];
}


- (IBAction)deleteYES:(id)sender {
    _deleteTagHandler();
    [popoverController dismissPopoverAnimated:true];
}
@end



