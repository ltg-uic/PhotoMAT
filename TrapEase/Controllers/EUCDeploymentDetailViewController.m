//
//  EUCDeploymentDetailViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/24/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDeploymentDetailViewController.h"
#import "EUCDeploymentImageCell.h"
#import "EUCBurst.h"
#import "EUCImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "EUCImageUtilities.h"
#import "EUCDeploymentImage.h"
#import "EUCImageDisplayViewController.h"
#import "NSString+EUCStringExtensions.h"
#import "EUCDatabase.h"
#import "EUCNetwork.h"
#import "DDLog.h"
#import "EUCFileSystem.h"

CGFloat defaultDeploymentWideness = 96.0/64.0;

static const int ddLogLevel = LOG_LEVEL_INFO;

typedef enum : NSUInteger {
    editingNominal,
    editingActual
} EUCDateEditingMode;

@interface EUCDeploymentDetailViewController ()


@property (weak, nonatomic) IBOutlet UITextField *shortName;
@property (weak, nonatomic) IBOutlet UITextView *notes;
@property (weak, nonatomic) IBOutlet UITextField *height;
@property (weak, nonatomic) IBOutlet UITextField *azimuth;
@property (weak, nonatomic) IBOutlet UITextField *elevation;
@property (weak, nonatomic) IBOutlet UITextField *nominal;
@property (weak, nonatomic) IBOutlet UITextField *actual;
@property (weak, nonatomic) IBOutlet UICollectionView *deploymentImages;
@property (weak, nonatomic) IBOutlet UICollectionView *bursts;
@property (weak, nonatomic) IBOutlet UIButton *addDeploymentImageButton;
@property (weak, nonatomic) IBOutlet UIButton *addBurstsButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *trapNumber;
@property (weak, nonatomic) IBOutlet UIButton *nominalButton;
@property (weak, nonatomic) IBOutlet UIButton *actualButton;
@property (strong, nonatomic) NSDate *nominalDate;
@property (strong, nonatomic) NSDate *actualDate;



@property (strong, nonatomic) NSMutableArray *importedBursts;
@property (strong, nonatomic) NSMutableArray *addedImages;
@property (strong, nonatomic) NSMutableArray *burstImages;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;

@property (assign, nonatomic) BOOL hasLibrary;
@property (assign, nonatomic) BOOL hasCamera;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIPopoverController *popover;
@property (weak, nonatomic) EUCImage * selectedImage;
@property (weak, nonatomic) NSMutableArray * selectedImageSource;
@property (assign, nonatomic) EUCDateEditingMode dateEditingMode;

@property (strong, nonatomic) EUCDatePickerViewController *datePickerViewController;
@property (strong, nonatomic) NSDateFormatter *format;
@property (strong, nonatomic) dispatch_queue_t uploadQueue;




- (IBAction)addImage:(id)sender;
- (IBAction)addBursts:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)enterNominal:(id)sender;
- (IBAction)enterActual:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@implementation EUCDeploymentDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
        _addedImages = [[NSMutableArray alloc] init];
        _burstImages = [[NSMutableArray alloc] init];
        _format = [[NSDateFormatter alloc] init];
        [_format setDateFormat:@"MMM dd, yyyy hh:mm a"];
        _uploadQueue = dispatch_queue_create("com.euclidsoftware.uploadQueue", NULL);


    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    CGRect frame = self.shortName.frame;
    frame.size.height = 48;
    self.shortName.frame = frame;

    UIColor * greyColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    self.notes.layer.borderColor = [greyColor CGColor];
    self.notes.layer.cornerRadius = 8;
    self.notes.layer.borderWidth = 1;
    
    self.deploymentImages.layer.borderColor = [greyColor CGColor];
    self.deploymentImages.layer.cornerRadius = 8;
    self.deploymentImages.layer.borderWidth = 1;
    
    self.bursts.layer.borderColor = [greyColor CGColor];
    self.bursts.layer.cornerRadius = 8;
    self.bursts.layer.borderWidth = 1;
    
    if (!self.editViewVisible) {
        [self clearEditView];
    }
    
    self.editView.hidden = !self.editViewVisible;
    
    
    self.addBurstsButton.hidden = self.updateMode;
    
    self.bursts.dataSource = self;
    self.bursts.delegate = self;
    self.deploymentImages.dataSource = self;
    self.deploymentImages.delegate = self;
    
    [self.bursts registerNib:[UINib nibWithNibName:@"EUCDeploymentImageCell" bundle:nil] forCellWithReuseIdentifier:@"deploymentImageCell"];
    [self.deploymentImages registerNib:[UINib nibWithNibName:@"EUCDeploymentImageCell" bundle:nil] forCellWithReuseIdentifier:@"deploymentImageCell"];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ImportDoneDelegate
-(void)importDone:(NSMutableArray *)bursts {
    self.importedBursts = bursts;
    
    BOOL first = YES;
    for (EUCBurst * burst in self.importedBursts) {
        for (EUCImage * image in burst.images) {
            if (first) {
                self.nominalDate = image.assetDate;
                first = NO;
            }
            [self.burstImages addObject:image];
        }
    }
    
    [self.bursts reloadData];
}

#pragma mark - edit view

-(void) clearEditView {
    self.shortName.text = @"";
    
}

-(void) setEditViewVisible:(BOOL)editViewVisible {
    _editViewVisible = editViewVisible;
    self.editView.hidden = !editViewVisible;
}

-(void) setUpdateMode:(BOOL)updateMode {
    _updateMode = updateMode;
    self.addBurstsButton.hidden = updateMode;
}

- (IBAction)addImage:(id)sender {
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

- (IBAction)addBursts:(id)sender {
    EUCImportViewController * import = [[EUCImportViewController alloc] initWithNibName:@"EUCImportViewController" bundle:nil];
    import.importDoneDelegate = self;
    [self presentViewController:import animated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    // verify that required fields are present
    BOOL okToContinue = [self verifyRequiredFields];
    if (!okToContinue) {
        return;
    }
    
    if (self.updateMode) {
        [self updateDeployment];
    }
    else {
        [self uploadDeployment];
    }
}

- (IBAction)enterNominal:(id)sender {
    [self resignKbResponders];
    self.dateEditingMode = editingNominal;
    self.datePickerViewController = [[EUCDatePickerViewController alloc] initWithNibName:@"EUCDatePickerViewController" bundle:nil date:self.nominalDate];
    self.datePickerViewController.delegate = self;
    
    self.popover = [[UIPopoverController alloc] initWithContentViewController:self.datePickerViewController];
    [self.popover presentPopoverFromRect:self.nominalButton.frame
                                  inView:self.view
                permittedArrowDirections:UIPopoverArrowDirectionAny
                                animated:YES];
    
}

- (IBAction)enterActual:(id)sender {
    [self resignKbResponders];
    self.dateEditingMode = editingActual;
    self.datePickerViewController = [[EUCDatePickerViewController alloc] initWithNibName:@"EUCDatePickerViewController" bundle:nil date:self.actualDate];
    self.datePickerViewController.delegate = self;
    
    self.popover = [[UIPopoverController alloc] initWithContentViewController:self.datePickerViewController];
    [self.popover presentPopoverFromRect:self.actualButton.frame
                                  inView:self.view
                permittedArrowDirections:UIPopoverArrowDirectionAny
                                animated:YES];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) resignKbResponders {
    [self.shortName resignFirstResponder];
    [self.trapNumber resignFirstResponder];
    [self.notes resignFirstResponder];
}

-(BOOL) verifyRequiredFields {
    if ([NSString isStringEmpty:self.shortName.text]) {
        [self alertForRequiredField:@"deployment name"];
        return NO;
    }
    if (self.actualDate == nil) {
        [self alertForRequiredField:@"mark time"];
        return NO;
    }
    if ([NSString isStringEmpty:self.trapNumber.text]) {
        [self alertForRequiredField:@"camera trap number"];
        return NO;
    }
    if (!self.updateMode) {
        if ([self.burstImages count] == 0) {
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"No bursts uploaded"
                                                                 message:@"Please upload at least one burst. You cannot add bursts later."
                                                                delegate:nil
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:@"OK", nil];
            
            [alertView show];
            return NO;
        }
    }

    return YES;
}

-(void) alertForRequiredField: (NSString *) field {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:[NSString stringWithFormat:@"Please enter a valid %@", field]
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil];
    [alertView show];
}

#pragma mark - UICollectionViewDataSource


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == self.bursts) {
        return [self.burstImages count];
    }
    else {
        return [self.addedImages count];
    }
    
}


-(EUCDeploymentImageCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCDeploymentImageCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"deploymentImageCell" forIndexPath:indexPath];
    
    EUCImage * imageToBeDisplayed;
    if (collectionView == self.bursts) {
        imageToBeDisplayed = self.burstImages[indexPath.row];
    }
    else {
        imageToBeDisplayed = self.addedImages[indexPath.row];
    }
    
    [self.assetsLibrary assetForURL:imageToBeDisplayed.url resultBlock:^(ALAsset *asset) {
        if (asset != nil) {
            UIImage * image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
            CGFloat wideness = 1.0*image.size.width/image.size.height;
            CGSize size;
            
            if (wideness > defaultDeploymentWideness) {
                size.width = 96;
                // width - height
                // 314
                size.height = 96/wideness;
            }
            else {
                size.height = 64;
                // width - height
                //         226
                size.width = 64 * wideness;
            }
            UIImage * resizedImage = [EUCImageUtilities imageWithImage:image scaledToSize:size];
            cell.imageView.image = resizedImage;
        }
        
    } failureBlock:^(NSError *error) {
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Cannot open image"
                                                             message:@"The image could not be found"
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil];
        
        [alertView show];
    }];
    
    
    return cell;
    
}



#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Image", @"image")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles: @"View", @"Delete",
                                  nil];
    actionSheet.tag = 1;
    actionSheet.destructiveButtonIndex = 1;
    
    if (collectionView == self.bursts) {
        self.selectedImageSource = self.burstImages;
        self.selectedImage = self.burstImages[indexPath.row];
    }
    else if (collectionView == self.deploymentImages) {
        self.selectedImageSource = self.addedImages;
        self.selectedImage = self.addedImages[indexPath.row];
    }
    else {
        self.selectedImageSource = nil;
        self.selectedImage = nil;
    }
    
    UIImage * image = [EUCImageUtilities blurredSnapshotForWindow:self.view.window];
    
    EUCImageDisplayViewController * display =
    [[EUCImageDisplayViewController alloc] initWithNibName:@"EUCImageDisplayViewController"
                                                    bundle:nil
                                           backgroundImage:image
                                                  assetURL:self.selectedImage.url];
    
    [self presentViewController:display animated:NO completion:nil];

    
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
            [self.popover presentPopoverFromRect:self.addDeploymentImageButton.bounds
                                          inView:self.addDeploymentImageButton
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
        else if (useCamera) {
            self.picker = [[UIImagePickerController alloc] init];
            self.picker.delegate = self;
            self.picker.allowsEditing = NO;
            self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
            [self.popover presentPopoverFromRect:self.addDeploymentImageButton.bounds
                                          inView:self.addDeploymentImageButton
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
        }
    }
    else if (actionSheet.tag == 1) { // view/delete
        if (buttonIndex ==  1) {
            // delete
            [self.selectedImageSource removeObject:self.selectedImage];
            if (self.selectedImageSource == self.burstImages) {
                [self.bursts reloadData];
            }
            else {
                [self.deploymentImages reloadData];
            }
            self.selectedImageSource = nil;
            self.selectedImage = nil;
        }
        else {
            // view
            UIImage * image = [EUCImageUtilities blurredSnapshotForWindow:self.view.window];
            
            EUCImageDisplayViewController * display =
            [[EUCImageDisplayViewController alloc] initWithNibName:@"EUCImageDisplayViewController"
                                                            bundle:nil
                                                   backgroundImage:image
                                                          assetURL:self.selectedImage.url];
            
            [self presentViewController:display animated:NO completion:nil];

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
    
    if (self.picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // from http://stackoverflow.com/questions/10166575/photo-taken-with-camera-does-not-contain-any-alasset-metadata≥
        [self.assetsLibrary writeImageToSavedPhotosAlbum:selectedImage.CGImage
                                                metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                                         completionBlock:^(NSURL *assetURL, NSError *error) {
                                             EUCImage * image = [[EUCImage alloc] initWithIndex:0 andUrl:assetURL];
                                             [self.addedImages addObject:image];
                                             [self.deploymentImages reloadData];
                                         }];
    }
    else {
        NSURL * assetURL = [info valueForKey:UIImagePickerControllerReferenceURL];
        EUCImage * image = [[EUCImage alloc] initWithIndex:0 andUrl:assetURL];
        [self.addedImages addObject:image];
        [self.deploymentImages reloadData];
    }
    
}

#pragma mark - Upload Deployment
-(void) uploadDeployment {
    NSDictionary * settings = [[EUCDatabase sharedInstance] settings];
    NSInteger personId = [settings[@"personId"] integerValue];
    NSInteger cameraId = 1; // hardcoded for now
    NSString * trapNumberString = self.trapNumber.text;
    NSInteger trapNumber = [trapNumberString integerValue];
    NSDictionary * putData = @{@"person_id": @(personId),
                                @"deployment_date": [self.format stringFromDate:self.actualDate],
                                @"camera": @(cameraId),
                                @"nominal_mark_time": [self.format stringFromDate:self.nominalDate],
                                @"actual_mark_time": [self.format stringFromDate:self.actualDate],
                                @"camera_trap_number": @(trapNumber),
                                @"short_name": self.shortName.text
                                };
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    
    [EUCNetwork createIDForResource:@"deployment"
                       successBlock:^(NSURLSessionDataTask *task, NSInteger newId) {
                           [EUCNetwork putResource:@"deployment"
                                            withId:newId
                                            params:putData successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                                DDLogInfo(@"Put deployment succeeded");
                                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                                [self dismissViewControllerAnimated:YES completion:nil];
                                                [self uploadBurstsToDeploymentNumber:newId];
                                                [self uploadImagesToDeploymentNumber:newId];
                                            } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                                DDLogInfo(@"Put failed");
                                            }];
                       }
                       failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                           DDLogInfo(@"Post failed");
                       }
     ];
    
}

-(void) uploadBurstsToDeploymentNumber: (NSInteger) deploymentId {
    // call createids for resuourse
    
    NSInteger numBursts = [self.importedBursts count];
    __block NSInteger burstIndex = 0;
    [EUCNetwork createIDs: numBursts forResource:@"burst"
                        successBlock:^(NSURLSessionDataTask *task, NSInteger burstId) {
                            EUCBurst * thisBurst = self.importedBursts[burstIndex];
                            burstIndex++;
                            EUCImage * firstImage = thisBurst.images[0];
                            
                            NSDictionary * putData = @{@"burst_date": [self.format stringFromDate:firstImage.assetDate],
                                                       @"deployment_id": @(deploymentId)};
                            
                            [EUCNetwork putResource:@"burst"
                                             withId:burstId
                                             params:putData
                                       successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                           DDLogInfo(@"Put burst succeeded");
                                           // now upload images
                                           [self uploadImagesForBurst: thisBurst withId: burstId];
//                                           [self saveImagesForBurst:thisBurst withId:burstId];
                                       } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                           // TODO: AAA alert here
                                       }];
                        } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                            // TODO: AAA alert here
                        }];
    
}


-(void) saveImagesForBurst: (EUCBurst *) burst withId: (NSInteger) burstId {
    
}

-(void) uploadImagesForBurst: (EUCBurst *) burst withId: (NSInteger) burstId {
    NSInteger numImages = [burst.images count];
    __block NSInteger imageIndex = 0;
    
    [EUCNetwork createIDs:numImages
              forResource:@"image"
             successBlock:^(NSURLSessionDataTask *task, NSInteger imageId) {
                 EUCImage * thisImage = burst.images[imageIndex];
                 imageIndex++;
                 NSDictionary * putData = @{@"burst_id": @(burstId),
                                            @"image_date": [self.format stringFromDate:thisImage.assetDate],
                                            @"file_name": [NSString stringWithFormat:@"%ld.jpg", (long)imageId],
                                            @"width": @(thisImage.dimensions.width),
                                            @"height": @(thisImage.dimensions.height)
                                            };
                 
                 // now put image
                 // then post to /image/file
                 [EUCNetwork putResource:@"image"
                                  withId:imageId
                                  params:putData
                            successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                // now upload images
                                dispatch_async(self.uploadQueue, ^(void) {
                                    [self uploadImageURL:thisImage.url forId:imageId];
                                });

//                                [self uploadImageURL:thisImage.url forId:imageId];
                            } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                // TODO: AAA alert here
                            }];
             } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                 // TODO: AAA alert here
             }];
}


-(void) uploadImageURL: (NSURL *) url forId: (NSInteger) imageId {
    [self.assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
        if (asset != nil) {
            // from: http://stackoverflow.com/a/8801656/772526
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(unsigned int)rep.size error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];


            NSString * fileName = [EUCFileSystem fileNameForImageWithId:imageId];
            
            [data writeToFile:fileName atomically:YES];
            // TODO: AAA write to pending database
//            [EUCNetwork uploadImageData: data forResource:@"image" withId:imageId];
        }
    }
                       failureBlock:^(NSError *error) {
                           // TODO: AAA log this
                       }
     ];
}

#pragma mark - Deployment Pictures

-(void) uploadImagesToDeploymentNumber: (NSInteger) deploymentId {
    NSInteger numImages = [self.addedImages count];
    __block NSInteger imageIndex = 0;
    NSInteger cameraId = 1; // hardcoded for now

    [EUCNetwork createIDs:numImages
              forResource:@"deployment_picture"
             successBlock:^(NSURLSessionDataTask *task, NSInteger imageId) {
                 EUCImage * thisImage = self.addedImages[imageIndex];
                 imageIndex++;
                 NSDictionary * putData = @{@"deployment_id": @(deploymentId),
                                            @"camera": @(cameraId),
                                            @"file_name": [NSString stringWithFormat:@"%ld.jpg", (long)imageId],
                                            @"file_type": @"jpg"
                                            };
                 
                 // now put image
                 // then post to /image/file
                 [EUCNetwork putResource:@"deployment_picture"
                                  withId:imageId
                                  params:putData
                            successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                // now upload images
                                dispatch_async(self.uploadQueue, ^(void) {
                                    [self uploadDeploymentPictureURL:thisImage.url forId:imageId];
                                });
                            } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                // TODO: AAA alert here
                            }];
             } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                 // TODO: AAA alert here
             }];
    
    
}


-(void) uploadDeploymentPictureURL: (NSURL *) url forId: (NSInteger) imageId {
    [self.assetsLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
        if (asset != nil) {
            // from: http://stackoverflow.com/a/8801656/772526
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(unsigned int)rep.size error:nil];
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];

            NSString * fileName = [EUCFileSystem fileNameForDeploymentPictureWithId:imageId];
            
            [data writeToFile:fileName atomically:YES];
            // TODO: AAA write to pending database
            
            //[EUCNetwork uploadImageData: data forResource:@"deployment_picture" withId:imageId];
        }
    }
                       failureBlock:^(NSError *error) {
                           // TODO: AAA log this
                       }
     ];
}


#pragma mark - Edit Deployment
-(void) updateDeployment {
}


#pragma mark - EUCDatePickerViewControllerDelegate
-(void) dateChangedTo:(NSDate *)date {
    
    if (self.dateEditingMode == editingNominal) {
        self.nominalDate = date;
        [self.nominalButton setTitle:[self.format stringFromDate:date] forState:UIControlStateNormal];
    }
    else {
        self.actualDate = date;
        [self.actualButton setTitle:[self.format stringFromDate:date] forState:UIControlStateNormal];
    }
}

#pragma mark - 

-(void) loadDeployment:(NSNumber *)deploymentId {
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSDictionary * record = [db getDeploymentRecord:deploymentId];
    self.shortName.text = record[@"short_name"];
    self.notes.text = record[@"notes"];
    self.trapNumber.text = [NSString stringWithFormat:@"%ld", (long)[record[@"camera_trap_number"] integerValue]];
    [self.actualButton setTitle:record[@"actual_mark_time"] forState:UIControlStateNormal];
    
    // get deployment images and bursts
    
}

@end
