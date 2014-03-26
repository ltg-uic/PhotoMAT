//
//  EUCConnectingViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/25/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCConnectingViewController.h"
#import "EUCNetwork.h"
#import "EUCDatabase.h"
#import "EUCAppDelegate.h"
#import "EUCHomeViewController.h"

@interface EUCConnectingViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *retryButton;
- (IBAction)retry:(id)sender;

@end

@implementation EUCConnectingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    [self retry: nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)retry:(id)sender {
    self.retryButton.hidden = YES;
    self.activityIndicator.hidden = NO;
    [EUCNetwork getSchoolsWithSuccessBlock:^(NSArray *objects) {
        self.activityIndicator.hidden = YES;

        EUCDatabase * db = [EUCDatabase sharedInstance];
        [db refreshSchools: objects];

        EUCAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
        appDelegate.window.rootViewController = appDelegate.homeViewController;
        
        
    
    } failureBlock:^(NSString *reason) {
        self.activityIndicator.hidden = YES;
        
        self.retryButton.hidden = NO;
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                             message:reason
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Retry", nil];
        
        [alertView show];
        
    }];
}

#pragma mark - Alertview

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [self retry: nil];
    }
}

@end
