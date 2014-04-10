//
//  EUCCloudViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCCloudViewController.h"

@interface EUCCloudViewController ()

@end

@implementation EUCCloudViewController

#define HOME_URL @"http://ltg.evl.uic.edu:8080/"

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Resources", "Resources")
                                                        image:[UIImage imageNamed:@"cloud"]
                                                selectedImage:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView.delegate = self;
    [self loadURL:[NSURL URLWithString:HOME_URL]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)loadURL:(NSURL *)url {
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
