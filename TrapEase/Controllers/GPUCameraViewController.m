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
@property (weak, nonatomic) IBOutlet UIView *filterView;
@property (strong, nonatomic) GPUImageGammaFilter * filter;


- (IBAction)shutter:(id)sender;

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
    self.preferredContentSize = CGSizeMake(640, 548);
    
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.stillCamera = [[GPUImageStillCamera alloc] init];
    self.stillCamera.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
    
    self.filter = [[GPUImageGammaFilter alloc] init];
    [self.stillCamera addTarget:self.filter];
    GPUImageView *filterView = (GPUImageView *)self.filterView;
    [self.filter addTarget:filterView];
    
    [self.stillCamera startCameraCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)shutter:(id)sender {

    [self.stillCamera capturePhotoAsImageProcessedUpToFilter:self.filter
                                             withOrientation:UIImageOrientationUp
                                       withCompletionHandler:^(UIImage *processedImage, NSError *error) {
                                           NSData *dataForJPGFile = UIImageJPEGRepresentation(processedImage, 0.8);
                                           
                                           NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                           NSString *documentsDirectory = [paths objectAtIndex:0];
                                           
                                           NSError *error2 = nil;
                                           if (![dataForJPGFile writeToFile:[documentsDirectory stringByAppendingPathComponent:@"FilteredPhoto.jpg"] options:NSAtomicWrite error:&error2])
                                           {
                                               return;
                                           }
                                           [self.delegate pictureTaken];
    }];
    
}
@end
