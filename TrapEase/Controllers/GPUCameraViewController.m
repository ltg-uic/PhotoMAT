//
//  GPUCameraViewController.m
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/13/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import "GPUCameraViewController.h"
#import "GPUImage.h"


@interface GPUCameraViewController () {}
@property (strong, nonatomic) GPUImageStillCamera *stillCamera;


@end

@implementation GPUCameraViewController

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
    
    
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.stillCamera = [[GPUImageStillCamera alloc] init];
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    GPUImageGammaFilter * filter = [[GPUImageGammaFilter alloc] init];
    [self.stillCamera addTarget:filter];
    GPUImageView *filterView = (GPUImageView *)self.view;
    [filter addTarget:filterView];
    
    [self.stillCamera startCameraCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
