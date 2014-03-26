//
//  EUCUserViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/25/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCUserViewController.h"
#import "EUCDatabase.h"

@interface EUCUserViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *school;
@property (weak, nonatomic) IBOutlet UIPickerView *classRoom;
@property (weak, nonatomic) IBOutlet UIPickerView *group;
@property (strong, nonatomic) NSArray *schools;

@end

@implementation EUCUserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Group", "Group")
                                                        image:[UIImage imageNamed:@"users.png"]
                                                selectedImage:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.school.dataSource = self;
    self.school.delegate = self;
    self.classRoom.dataSource = self;
    self.classRoom.delegate = self;
    self.group.dataSource = self;
    self.group.delegate = self;
    
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.schools = [[EUCDatabase sharedInstance] schools];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIPickerViewDataSource

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (pickerView == self.school) {
        return [self.schools count];
    }
    else if (pickerView == self.classRoom) {
        NSInteger schoolRow = [self.school selectedRowInComponent:0];
        return ([self.schools[schoolRow][@"class"] count]);
    }
    else if (pickerView == self.group) {
        NSInteger schoolRow = [self.school selectedRowInComponent:0];
        NSInteger classRow = [self.classRoom selectedRowInComponent:0];
        return ([self.schools[schoolRow][@"class"][classRow][@"person"] count]);
    }
    else {
        return 0;
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

#pragma mark - UIPickerViewDelegate

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView == self.school) {
        return self.schools[row][@"name"];
    }
    else if (pickerView == self.classRoom) {
        NSInteger schoolRow = [self.school selectedRowInComponent:0];
        return (self.schools[schoolRow][@"class"][row][@"name"]);
    }
    else if (pickerView == self.group) {
        NSInteger schoolRow = [self.school selectedRowInComponent:0];
        NSInteger classRow = [self.classRoom selectedRowInComponent:0];
        return (self.schools[schoolRow][@"class"][classRow][@"person"][row][@"first_name"]);
    }
    else {
        return @"";
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
}

//-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
//    return 44;
//}
//
//-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
//    return 390;
//}
@end
