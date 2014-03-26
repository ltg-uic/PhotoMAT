
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

@property (assign, nonatomic) NSInteger schoolRow;
@property (assign, nonatomic) NSInteger classRow;
@property (assign, nonatomic) NSInteger groupRow;

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
        _schoolRow = _classRow = _groupRow = 0;
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
    [self.school reloadAllComponents];
    [self.classRoom reloadAllComponents];
    [self.group reloadAllComponents];
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
        return ([self.schools[self.schoolRow][@"class"] count]);
    }
    else if (pickerView == self.group) {
        NSInteger num =  ([self.schools[self.schoolRow][@"class"][self.classRow][@"person"] count]);
        return num;
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
        return (self.schools[self.schoolRow][@"class"][row][@"name"]);
    }
    else if (pickerView == self.group) {
        NSString * str =  (self.schools[self.schoolRow][@"class"][self.classRow][@"person"][row][@"firstName"]);
        return str;
    }
    else {
        return @"";
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == self.school) {
        self.schoolRow = [self.school selectedRowInComponent:0];
        self.classRow = 0;
        self.groupRow = 0;
        [self.classRoom reloadAllComponents];
        [self.group reloadAllComponents];
        [self.classRoom selectRow:0 inComponent:0 animated:YES];
        [self.group selectRow:0 inComponent:0 animated:YES];
    }
    else if (pickerView == self.classRoom) {
        self.classRow = [self.classRoom selectedRowInComponent:0];
        self.groupRow = 0;
        [self.group reloadAllComponents];
        [self.group selectRow:0 inComponent:0 animated:YES];
    }
    else {
        self.groupRow = [self.group selectedRowInComponent:0];
    }
}

//-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
//    return 44;
//}
//
//-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
//    return 390;
//}
@end
