//
//  EUCKnapsackViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCKnapsackViewController.h"

@interface EUCKnapsackViewController () {}

@property (assign, nonatomic) BOOL asSnapshot;

@end

@implementation EUCKnapsackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil asSnapshot: (BOOL) asSnapshot {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _asSnapshot = asSnapshot;
        if (asSnapshot) {
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Screenshot", "Screenshot")
                                                            image:[UIImage imageNamed:@"camera"]
                                                    selectedImage:nil];
        }
        else {
            self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Photos", "Photos")
                                                            image:[UIImage imageNamed:@"photo"]
                                                    selectedImage:nil];
        }
        
    }
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Knapsack", "Knapsack")
                                                        image:[UIImage imageNamed:@"hiking"]
                                                selectedImage:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (self.asSnapshot) {
        self.importButton.hidden = YES;
        self.clearButton.hidden = YES;
    }
    else {
        self.saveButton.hidden = YES;
        self.clearButton.hidden = YES;
    }
    UIColor * greyColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];

    self.imageView.layer.borderColor = [greyColor CGColor];
    self.imageView.layer.cornerRadius = 8;
    self.imageView.layer.borderWidth = 1;
    
    self.textView.layer.borderColor = [greyColor CGColor];
    self.textView.layer.cornerRadius = 8;
    self.textView.layer.borderWidth = 1;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clear:(id)sender {
}

- (IBAction)save:(id)sender {
}

- (IBAction)import:(id)sender {
}
@end
