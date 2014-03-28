//
//  EUCImageDisplayViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/28/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImageDisplayViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface EUCImageDisplayViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;

@property (weak, nonatomic) IBOutlet UIImageView *displayImage;

@property (strong, nonatomic) UIImage *backgroundImage;

@property (strong, nonatomic) NSURL * assetURL;

- (IBAction)done:(id)sender;
@end

@implementation EUCImageDisplayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil backgroundImage: (UIImage *) backgroundImage assetURL: (NSURL *) assetURL
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _backgroundImage = backgroundImage;
        _assetURL = assetURL;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.backgroundImageView.image = self.backgroundImage;
    
    ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:self.assetURL
             resultBlock:^(ALAsset *asset) {
                 UIImage * image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
                 self.displayImage.image = image;
             } failureBlock:^(NSError *error) {
                 UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                      message:@"Cannot open image"
                                                                     delegate:nil
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles:@"OK", nil];
                 
                 [alertView show];
             }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
