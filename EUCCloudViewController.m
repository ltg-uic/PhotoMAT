//
//  EUCCloudViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCCloudViewController.h"
#import "EUCAppDelegate.h"
#import "EUCSelectedSet.h"

@interface EUCCloudViewController () {
    EUCAppDelegate *appDelegate;
}
@end

@implementation EUCCloudViewController

#define HOME_URL @"http://ltg.evl.uic.edu:8080/"
#define ICS_URL @"http://ltg.evl.uic.edu:8080/"


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Resources", "Resources")
                                                        image:[UIImage imageNamed:@"cloud"]
                                                selectedImage:nil];

        appDelegate = (EUCAppDelegate *) [[UIApplication sharedApplication] delegate];

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _webView.delegate = self;
    [self selectURL];
}

- (void)viewDidAppear:(BOOL)animated {
    [_webView reload];
}

- (void)selectURL {
    EUCSelectedSet *selectedSet = [EUCSelectedSet sharedInstance];

    if ([[selectedSet schoolName] isEqualToString:@"ICS"]) {
        [self loadURL:[NSURL URLWithString:ICS_URL]];
    } else {
        [self loadURL:[NSURL URLWithString:HOME_URL]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadURL:(NSURL *)url {
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    if (_webView.canGoBack) {
        _backButton.enabled = YES;
    }
    else {
        _backButton.enabled = NO;
    }

    if (_webView.canGoForward) {
        _forwardButton.enabled = YES;
    }
    else {
        _forwardButton.enabled = NO;
    }

}

- (IBAction)goBack:(id)sender {
    [_webView goBack];
}

- (IBAction)goForward:(id)sender {
    [_webView goForward];
}

- (IBAction)goHome:(id)sender {
    [self loadURL:[NSURL URLWithString:HOME_URL]];
}

#pragma mark - LoginChangedDelegate

- (void)loginDidChangeToSchool:(NSString *)schoolName {
    // do stuff here
}

@end
