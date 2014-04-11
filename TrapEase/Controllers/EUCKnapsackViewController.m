//
//  EUCKnapsackViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCKnapsackViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface EUCKnapsackViewController () {}

@property (assign, nonatomic) BOOL asSnapshot;
@property (assign, nonatomic) BOOL hasCamera;
@property (assign, nonatomic) BOOL hasLibrary;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIPopoverController *popover;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;

@end

@implementation EUCKnapsackViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil asSnapshot: (BOOL) asSnapshot {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _assetsLibrary = [[ALAssetsLibrary alloc] init];

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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Source", @"selectSource")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  nil];
    actionSheet.tag = 0;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Camera", @"Camera")];
        self.hasCamera = YES;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Photo Library", @"Photo Library")];
        self.hasLibrary = YES;
    }
    
    [actionSheet showFromRect:[(UIButton *)sender frame] inView:self.view animated:YES];

}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0) {
        NSInteger i = buttonIndex;
        BOOL useLibrary = NO;
        BOOL useCamera = NO;
        
        if (self.hasLibrary) {
            if (self.hasCamera) {
                if (i == 0) { useCamera = YES; }
                else if (i == 1) { useLibrary = YES; }
            }
            else {
                if (i == 0) { useLibrary = YES; }
            }
        }
        else {
            if (self.hasCamera) {
                if (i == 0) { useCamera = YES; }
            }
        }
        
        if (useLibrary) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
            [self.popover presentPopoverFromRect:self.importButton.bounds
                                          inView:self.importButton
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
        else if (useCamera) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.allowsEditing = NO;
            self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
            [self.popover presentPopoverFromRect:self.importButton.bounds
                                          inView:self.importButton
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Picking Image from Camera/ Library
    [self.popover dismissPopoverAnimated:YES];
    UIImage * selectedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    if (!selectedImage) {
        return;
    }
    
//    if (self.picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
//        // from http://stackoverflow.com/questions/10166575/photo-taken-with-camera-does-not-contain-any-alasset-metadata≥
//        [self.assetsLibrary writeImageToSavedPhotosAlbum:selectedImage.CGImage
//                                                metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
//                                         completionBlock:^(NSURL *assetURL, NSError *error) {
//                                             EUCImage * image = [[EUCImage alloc] initWithIndex:0 andUrl:assetURL];
//                                             [self.addedImages addObject:image];
//                                             [self.deploymentImages reloadData];
//                                         }];
//    }
//    else {
//        NSURL * assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
//        EUCImage * image = [[EUCImage alloc] initWithIndex:0 andUrl:assetURL];
//        [self.addedImages addObject:image];
//        [self.deploymentImages reloadData];
//    }
    
}


@end
