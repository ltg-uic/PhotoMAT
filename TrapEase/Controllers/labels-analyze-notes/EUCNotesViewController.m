//
//  EUCCloudViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCNotesViewController.h"
#import "EUCDatabase.h"

@interface EUCNotesViewController ()

@end

@implementation EUCNotesViewController

#define HOME_URL @"http://safari.encorelab.org/mobile/mobile.html"

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Notes", "Notes")
                                                        image:[UIImage imageNamed:@"note"]
                                                selectedImage:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _webView.delegate = self;


//    EUCDatabase * db = [EUCDatabase sharedInstance];
//    NSString * groupName = db.groupName;
//    NSString * className = db.className;
//
//
//    NSString *fullURL = [NSString stringWithFormat:@"http://safari.encorelab.org/mobile/mobile.html?runId=%@&username=%@", className, groupName];
//
//    NSURL *url = [NSURL URLWithString:fullURL];
//
//
//    [self loadURL:url];
}

- (void)viewWillAppear:(BOOL)animated {

    EUCDatabase *db = [EUCDatabase sharedInstance];
    NSString *groupName = db.groupName;
    NSString *className = db.className;

    NSString *fullURL = [NSString stringWithFormat:@"http://safari.encorelab.org/mobile/mobile.html?runId=%@&username=%@&showLogout=false", className, groupName];

    NSURL *url = [NSURL URLWithString:fullURL];


    [self loadURL:url];
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


@end
