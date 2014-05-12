//
//  CountPickerViewController.m
//  PhotoMat
//
//  Created by Anthony Perritano on 5/10/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "CountPickerViewController.h"

@interface CountPickerViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@end

@implementation CountPickerViewController {
    NSMutableArray *burstIndexes;
    NSString *selelectedIndex;
}

@synthesize burstIndexes;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        burstIndexes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)selectRow:(int)selectedIndex {

    [_indexPicker reloadAllComponents];

    if (selectedIndex < 0)
        selectedIndex = 0;

    [_indexPicker selectRow:selectedIndex inComponent:0 animated:YES];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectIndex:(id)sender {
    _finishedHandler(selelectedIndex);
    [_somePopoverController dismissPopoverAnimated:true];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return burstIndexes.count;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    selelectedIndex = [burstIndexes objectAtIndex:row];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [burstIndexes objectAtIndex:row];

}

@end
