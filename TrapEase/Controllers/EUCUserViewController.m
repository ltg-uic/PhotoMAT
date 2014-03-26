
//
//  EUCUserViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/25/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCUserViewController.h"
#import "EUCDatabase.h"
#import "EUCNetwork.h"

@interface EUCUserViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *school;
@property (weak, nonatomic) IBOutlet UIPickerView *classRoom;
@property (weak, nonatomic) IBOutlet UIPickerView *group;
@property (strong, nonatomic) NSArray *schools;

@property (assign, nonatomic) NSInteger schoolRow;
@property (assign, nonatomic) NSInteger classRow;
@property (assign, nonatomic) NSInteger groupRow;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *visibility;

- (IBAction)refresh:(id)sender;
- (IBAction)done:(id)sender;
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
    
    self.activityIndicator.hidden = YES;
    
    self.school.dataSource = self;
    self.school.delegate = self;
    self.classRoom.dataSource = self;
    self.classRoom.delegate = self;
    self.group.dataSource = self;
    self.group.delegate = self;

    [self.visibility addTarget:self
                         action:@selector(done:)
               forControlEvents:UIControlEventValueChanged];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshControlsWithData];
}

-(void) refreshControlsWithData {
    self.schools = [[EUCDatabase sharedInstance] schools];
    
    self.schoolRow = self.classRow = self.groupRow = 0;
    
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSDictionary * settings = db.settings;
    NSString * visibility = settings[@"visibility"];
    if ([visibility isEqualToString:@"class"]) {
        self.visibility.selectedSegmentIndex = 0;
    }
    else if ([visibility isEqualToString:@"school"]) {
        self.visibility.selectedSegmentIndex = 1;
    }
    else {
        self.visibility.selectedSegmentIndex = 2;
    }
        
    
    for (NSDictionary * school in self.schools) {
        if ([school[@"id"] isEqualToNumber:settings[@"schoolId"]]) {
            for (NSDictionary * classRoom in school[@"class"]) {
                if ([classRoom[@"id"] isEqualToNumber: settings[@"classId"]]) {
                    for (NSDictionary * person in classRoom[@"person"]) {
                        if ([person[@"id"] isEqualToNumber:settings[@"personId"]]) {
                            [self reloadAllPickers];
                            return;
                        }
                        self.groupRow = self.groupRow + 1;
                    }
                }
                self.classRow = self.classRow + 1;
            }
            break;
        }
        self.schoolRow = self.schoolRow + 1;
    }

    // if you got here, you didn't find a match for all 3, school, class and group
    self.schoolRow = self.classRow = self.groupRow = 0;

    
    [self reloadAllPickers];
    
}

-(void) reloadAllPickers {
    [self.school reloadAllComponents];
    [self.classRoom reloadAllComponents];
    [self.group reloadAllComponents];
    [self.school selectRow:self.schoolRow inComponent:0 animated:YES];
    [self.classRoom selectRow:self.classRow inComponent:0 animated:YES];
    [self.group selectRow:self.groupRow inComponent:0 animated:YES];
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
    [self done:nil];
}


- (IBAction)refresh:(id)sender {
    self.activityIndicator.hidden = NO;
    [EUCNetwork getSchoolsWithSuccessBlock:^(NSArray *objects) {
        self.activityIndicator.hidden = YES;
        
        EUCDatabase * db = [EUCDatabase sharedInstance];
        [db refreshSchools: objects];
        
        [self refreshControlsWithData];
        
    } failureBlock:^(NSString *reason) {
        self.activityIndicator.hidden = YES;
        
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:reason
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil];
        
        [alertView show];
        
    }];
}

- (IBAction)done:(id)sender {
    NSString * visibilityString;
    if (self.visibility.selectedSegmentIndex == 0) {
        visibilityString = @"class";
    }
    else if (self.visibility.selectedSegmentIndex == 1) {
        visibilityString = @"school";
    }
    else {
        visibilityString = @"world";
    }
    
    NSDictionary * settings = @{
        @"schoolId": self.schools[self.schoolRow][@"id"],
        @"classId": self.schools[self.schoolRow][@"class"][self.classRow][@"id"],
        @"personId": self.schools[self.schoolRow][@"class"][self.classRow][@"person"][self.groupRow][@"id"],
        @"visibility": visibilityString
        };
    
    EUCDatabase * db = [EUCDatabase sharedInstance];
    db.settings = settings;
}

        
@end
