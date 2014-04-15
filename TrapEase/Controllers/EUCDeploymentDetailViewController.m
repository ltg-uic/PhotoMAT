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
#import "EUCTimeUtilities.h"
#import "Toast+UIView.h"

CGFloat defaultDeploymentWideness = 96.0/64.0;

static const int ddLogLevel = LOG_LEVEL_INFO;

typedef enum : NSUInteger {
    editingNominal,
    editingActual
} EUCDateEditingMode;

@interface EUCDeploymentDetailViewController () {
    UIPopoverController *imagePopoverController;
}

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
@property (weak, nonatomic) IBOutlet UILabel *deploymentIdLabel;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *downloadActivityIndicator;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (weak, nonatomic) IBOutlet UILabel *downloadStatus;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;




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
@property (strong, nonatomic) NSDateFormatter *parser;

@property (strong, nonatomic) dispatch_queue_t uploadQueue;


@property (strong, nonatomic) NSDate *nominalDate;
@property (strong, nonatomic) NSDate *actualDate;
@property (strong, nonatomic) NSMutableArray *importedBursts;
@property (strong, nonatomic) NSMutableArray *addedImages;
@property (strong, nonatomic) NSMutableArray *burstImages;

@property (assign, nonatomic) NSInteger numberToDownload;
@property (assign, nonatomic) NSInteger numberDownloaded;


- (IBAction)addImage:(id)sender;
- (IBAction)addBursts:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)enterNominal:(id)sender;
- (IBAction)enterActual:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)download:(id)sender;

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
        _parser = [[NSDateFormatter alloc] init];
        [_parser setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    CGRect frame = self.shortName.frame;
    frame.size.height = 48;
   // self.shortName.frame = frame;
    
    [self textViewLikeTextField:_notes];

    UIColor * greyColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
//    self.notes.layer.borderColor = [greyColor CGColor];
//    self.notes.layer.cornerRadius = 8;
//    self.notes.layer.borderWidth = 1;
    
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

//changes the look of the textfield
- (void)textViewLikeTextField:(UITextView *)textView {
    [textView.layer setBorderColor:[[UIColor colorWithRed:232.0 / 255.0
                                                    green:232.0 / 255.0 blue:232.0 / 255.0 alpha:1] CGColor]];
    [textView.layer setBorderWidth:1.0f];
    [textView.layer setCornerRadius:7.0f];
    [textView.layer setMasksToBounds:YES];
}

#pragma mark - ImportDoneDelegate
-(void)importDone:(NSMutableArray *)bursts {
    self.importedBursts = bursts;
    
    [self.view makeToastActivity];
    
    BOOL first = YES;
    __block NSInteger imageNumber = 0;
    NSInteger numImages = 0;
    for (EUCBurst * burst in self.importedBursts) {
        numImages += [burst.images count];
    }
    
    for (EUCBurst * burst in self.importedBursts) {
        for (EUCImage * image in burst.images) {
            if (first) {
                self.nominalDate = image.assetDate;
                first = NO;
            }
            [self.burstImages addObject:image];
            [self.assetsLibrary assetForURL:image.url resultBlock:^(ALAsset *asset) {
                if (asset != nil) {
                    // from: http://stackoverflow.com/a/8801656/772526
                    ALAssetRepresentation *rep = [asset defaultRepresentation];
                    Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
                    NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(unsigned int)rep.size error:nil];
                    NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                    NSString *documentsDirectory = [EUCFileSystem documentDir];
                    NSString *imagesDirectory = [documentsDirectory stringByAppendingPathComponent:@"images"];
                    NSString * fileName = [imagesDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"_d%ld.jpg", imageNumber]];
                    [data writeToFile:fileName atomically:YES];
                    [self resizeFileNamed:fileName fromSize:rep.dimensions];
                    image.filename = fileName;
                    imageNumber++;
                    if (imageNumber >= numImages) {
                        [self.view hideToastActivity];
                        [self.bursts reloadData];
                    }

                }
            }
                               failureBlock:^(NSError *error) {
                                   // TODO: AAA log this
                               }
             ];
            
        }
    }
    
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
    
    self.doneButton.hidden = updateMode;
    self.cancelButton.hidden = updateMode;
    self.addDeploymentImageButton.hidden = updateMode;
    self.shortName.enabled = !updateMode;
    self.notes.editable = !updateMode;
    self.trapNumber.enabled = !updateMode;
    self.actualButton.enabled = !updateMode;

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
//    if ([NSString isStringEmpty:self.trapNumber.text]) {
//        [self alertForRequiredField:@"camera trap number"];
//        return NO;
//    }
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
    
    UIImage * image = [UIImage imageWithContentsOfFile:[self thumbnailFileNameForFile: imageToBeDisplayed.filename]];
    cell.imageView.image = image;
    
    return cell;
    
}



#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    EUCDeploymentImageCell *imageDeployCell = [self collectionView:collectionView cellForItemAtIndexPath:indexPath];


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
                                                  assetURL:self.selectedImage.url
     fileName:self.selectedImage.filename];

    imagePopoverController = [[UIPopoverController alloc]
            initWithContentViewController:display];

    [imagePopoverController setPopoverContentSize:display.view.frame.size animated:true];

    if([collectionView isEqual:_bursts]) {
        [imagePopoverController presentPopoverFromRect:imageDeployCell.frame inView:_bursts  permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    } else {
        [imagePopoverController presentPopoverFromRect:imageDeployCell.frame inView:_deploymentImages  permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
    }

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
            GPUCameraViewController * cameraVC = [[GPUCameraViewController alloc] init];
            cameraVC.delegate = self;
            self.popover = [[UIPopoverController alloc] initWithContentViewController:cameraVC];
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
                                                          assetURL:self.selectedImage.url
             fileName:self.selectedImage.filename];
            
            


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
        
        [self.assetsLibrary assetForURL:image.url resultBlock:^(ALAsset *asset) {
            if (asset != nil) {
                // from: http://stackoverflow.com/a/8801656/772526
                ALAssetRepresentation *rep = [asset defaultRepresentation];
                Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
                NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:(unsigned int)rep.size error:nil];
                NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
                NSString *documentsDirectory = [EUCFileSystem documentDir];
                NSString *imagesDirectory = [documentsDirectory stringByAppendingPathComponent:@"images"];
                NSString * fileName = [imagesDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"_d%ld.jpg", time(NULL)]];
                [data writeToFile:fileName atomically:YES];
                [self resizeFileNamed:fileName fromSize:rep.dimensions];
                image.filename = fileName;
                [self.addedImages addObject:image];
                [self.deploymentImages reloadData];
            }
        }
                           failureBlock:^(NSError *error) {
                               // TODO: AAA log this
                           }
         ];
        
    }
    
}

-(void)pictureTaken {
    // Picking Image from Camera/ Library
    [self.popover dismissPopoverAnimated:YES];

   
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagesDirectory = [documentsDirectory stringByAppendingPathComponent:@"images"];
    NSString * destination = [imagesDirectory stringByAppendingPathComponent: [NSString stringWithFormat:@"_d%ld.jpg", time(NULL)]];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    [fileManager copyItemAtPath:[documentsDirectory stringByAppendingPathComponent:@"FilteredPhoto.jpg"]
                         toPath:destination
                          error:nil];
    UIImage * timage = [UIImage imageWithContentsOfFile:destination];
    [self resizeFileNamed:destination fromSize:timage.size];
    
    EUCImage * image = [[EUCImage alloc] initWithIndex:0 andUrl:nil];
    image.filename = destination;
    [self.addedImages addObject:image];
    [self.deploymentImages reloadData];
    
}

#pragma mark - Upload Deployment
-(void) sendSafari: (NSInteger) deploymentId {
    // http://drowsy.badger.encorelab.org/safari-ben/safari
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSString * className = [db className];
    NSString * groupName = [db groupName];
    
    BOOL DEV = NO;
    
    
    NSString * safariURL;
    if (DEV) {
        safariURL = [NSString stringWithFormat:@"http://drowsy.badger.encorelab.org/dev-safari-%@/safaris", className];
    }
    else {
        safariURL = [NSString stringWithFormat:@"http://drowsy.badger.encorelab.org/safari-%@/safaris", className];
    }
    
    NSDictionary * body = @{@"id": @(deploymentId),
                            @"created_at": [EUCTimeUtilities currentTimeInZulu],
                            @"name": [NSString stringWithFormat:@"%ld-%@", deploymentId, self.shortName.text],
                            @"group": groupName
                            };
    
    [EUCNetwork sendSafari:body
                     toUrl:safariURL
              successBlock:^(AFHTTPRequestOperation *operation, id responseObject) {
                  // do nothing
              } failureBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
                  UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                       message:[NSString stringWithFormat:@"Could not post safari: %@", [error localizedDescription]]
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK"
                                                             otherButtonTitles: nil];
                  
                  [alertView show];
              }];

}

-(void) uploadDeployment {
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSDictionary * settings = [db settings];
    NSInteger personId = [settings[@"personId"] integerValue];
    // NSString * trapNumberString = self.trapNumber.text;
    NSInteger trapNumber = -1; // [trapNumberString integerValue];
    NSInteger cameraId = 1;
    
    NSInteger deploymentId = [db getMinIdForTable:@"deployment"];
    [db saveLocalDeploymentWithId: deploymentId
                        person_id: personId
                  deployment_date: [self.format stringFromDate:self.actualDate]
                         cameraId: cameraId
                  nominalMarkTime: [self.format stringFromDate:self.nominalDate]
                   actualMarkTime: [self.format stringFromDate:self.actualDate]
               camera_trap_number: trapNumber
                       short_name: self.shortName.text
                            notes: self.notes.text
     ];
    
    // save deployment_pictures
    for (EUCImage * deployment_picture in self.addedImages) {
        NSInteger deploymentPictureId = [db getMinIdForTable:@"deployment_picture"];

        NSString * fileName = [EUCFileSystem fileNameForDeploymentPictureWithId:deploymentPictureId];
        [EUCFileSystem moveFile:[self thumbnailFileNameForFile:deployment_picture.filename] toFile:[self thumbnailFileNameForFile:fileName]]; // move thumbnail
        [EUCFileSystem moveFile:deployment_picture.filename toFile:fileName];
        deployment_picture.filename = fileName;
        
        [db saveLocalDeploymentPictureWithId: deploymentPictureId
                                       owner: personId
                               deployment_id: deploymentId
                                    fileName: fileName
         ];
    }
    
    // save burst
    for (EUCBurst * burst in self.importedBursts) {
        NSInteger burstId = [db getMinIdForTable:@"burst"];
        EUCImage * firstImage = burst.images[0];
        [db saveLocalBurstWithId:burstId owner:personId deployment_id:deploymentId burstDate:[self.format stringFromDate:firstImage.assetDate]];
        
        for (EUCImage * image in burst.images) {
            [self.assetsLibrary assetForURL:image.url resultBlock:^(ALAsset *asset) {
                if (asset != nil) {
                    NSInteger imageId = [db getMinIdForTable:@"image"];
                    NSString * fileName = [EUCFileSystem fileNameForImageWithId:imageId];
                    [EUCFileSystem moveFile:[self thumbnailFileNameForFile:image.filename] toFile:[self thumbnailFileNameForFile:fileName]]; // move thumbnail
                    [EUCFileSystem moveFile:image.filename toFile:fileName];
                    image.filename = fileName;
                    
                    [db saveLocalBurstImageWithId:imageId owner:personId imageDate:[self.format stringFromDate:image.assetDate] burstId:burstId fileName:fileName width:image.dimensions.width height:image.dimensions.height];
                }
            }
                               failureBlock:^(NSError *error) {
                                   // TODO: AAA log this
                               }
             ];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];

}

-(void) old_uploadDeployment {
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
                                @"short_name": self.shortName.text,
                                @"notes":self.notes.text
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
                                                [self sendSafari: newId];
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
                                    [self uploadImageURL:thisImage.url forId:imageId];

//                                [self uploadImageURL:thisImage.url forId:imageId];
                            } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                // TODO: AAA alert here
                            }];
             } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                 // TODO: AAA alert here
             }];
}

-(void) resizeFileNamed:(NSString *) fileName fromSize: (CGSize) origSize {
    CGFloat wideness = 1.0*origSize.width/origSize.height;
    CGSize newSize;
    if (wideness > defaultDeploymentWideness) {
        newSize.width = 96;
        newSize.height = 96/wideness;
    }
    else {
        newSize.height = 64;
        newSize.width = 64 * wideness;
    }
    [EUCImageUtilities resizeImageAtFile:fileName toSize:newSize toFile:[self thumbnailFileNameForFile:fileName]];
}

-(NSString *) thumbnailFileNameForFile: (NSString *) fileName {
    NSInteger length = [fileName length];
    NSString * newFileName = [NSString stringWithFormat:@"%@t.jpg", [fileName substringToIndex:length - 4]];
    return newFileName;
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
            [self resizeFileNamed:fileName fromSize:rep.dimensions];

            
            [[EUCDatabase sharedInstance] writePendingUploadOf:fileName withType:@"image" andId:imageId];
            [[EUCDatabase sharedInstance] consumePendingQueue];
            
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
//                                [self uploadDeploymentPictureURL:thisImage.url forId:imageId];
                                [self uploadDeploymentPictureFile:thisImage.filename forId:imageId];
                            } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                // TODO: AAA alert here
                            }];
             } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                 // TODO: AAA alert here
             }];
    
    
}

-(void) uploadDeploymentPictureFile: (NSString *) file forId: (NSInteger) imageId {
    UIImage * image = [UIImage imageWithContentsOfFile:file];
    
    NSData * data = [NSData dataWithContentsOfFile:file];
    NSString * fileName = [EUCFileSystem fileNameForDeploymentPictureWithId:imageId];
    
    [data writeToFile:fileName atomically:YES];
    CGSize dimensions = [image size];
    [self resizeFileNamed:fileName fromSize:dimensions];
    
    
    [[EUCDatabase sharedInstance] writePendingUploadOf:fileName withType:@"deployment_picture" andId:imageId];
    [[EUCDatabase sharedInstance] consumePendingQueue];
    
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
            [self resizeFileNamed:fileName fromSize:rep.dimensions];
            
            
            [[EUCDatabase sharedInstance] writePendingUploadOf:fileName withType:@"deployment_picture" andId:imageId];
            [[EUCDatabase sharedInstance] consumePendingQueue];
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
    
    NSString * dateString = record[@"actual_mark_time"];
    self.actualDate = [self.parser dateFromString:dateString];

    
    // local get
    NSInteger deploymentIdInteger = [deploymentId integerValue];
    self.deploymentIdLabel.text = [NSString stringWithFormat:@"%ld", (long)[record[@"id"] integerValue]];
    self.numberDownloaded = 0;
    self.numberToDownload = 0;
    self.downloadActivityIndicator.hidden = YES;
    self.downloadProgressView.hidden = YES;
    self.downloadButton.hidden = YES;
    
    self.addedImages = [db getDeploymentImagesForDeploymentWithId:deploymentIdInteger];
    self.importedBursts = [db getBurstForDeploymentWithId:deploymentIdInteger withParser: self.parser];
    [self.burstImages removeAllObjects];
    for (EUCBurst * burst in self.importedBursts) {
        for (EUCImage * image in burst.images) {
            [self.burstImages addObject:image];
        }
    }
    [self.bursts reloadData];
    [self.deploymentImages reloadData];
    
    
}

-(void) populateFromDictionary: (NSDictionary *) dictionary {
    self.deploymentIdLabel.text = [NSString stringWithFormat:@"%ld", (long)[dictionary[@"id"] integerValue]];
    NSMutableArray * bursts = [NSMutableArray arrayWithCapacity:64];
    NSArray * burstArray = dictionary[@"burst"];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    self.numberDownloaded = 0;
    self.numberToDownload = 0;
    self.downloadActivityIndicator.hidden = YES;
    self.downloadProgressView.hidden = YES;
    self.downloadButton.hidden = YES;

    for (NSDictionary * burstDictionary in burstArray) {
        EUCBurst * newBurst = [[EUCBurst alloc] init];
        newBurst.burstId = [burstDictionary[@"id"] integerValue];
        
        NSArray * imageArray = burstDictionary[@"image"];
        for (NSDictionary * imageDictionary in imageArray) {
            EUCImage * newImage = [[EUCImage alloc] init];
            newImage.assetDate = [self.parser dateFromString:imageDictionary[@"image_date"]];;
            newImage.dimensions = CGSizeMake([imageDictionary[@"width"] floatValue], [imageDictionary[@"height"] floatValue]);
            newImage.filename = [EUCFileSystem fileNameForImageWithId:[imageDictionary[@"id"] integerValue]];
            [newBurst.images addObject:newImage];
            self.numberToDownload++;
            if ([fileManager fileExistsAtPath:newImage.filename]) {
                self.numberDownloaded++;
                newImage.isLocal = YES;
            }
        }
        [bursts addObject:newBurst];
    }
    [self.burstImages removeAllObjects];
    [self importDone:bursts];
    
    // now deployment images
    
    [self.addedImages removeAllObjects];
    
    NSArray * pictureArray = dictionary[@"deployment_picture"];
    if (![pictureArray isEqual:[NSNull null]]) {
        for (NSDictionary * pictureDictionary in pictureArray) {
            EUCImage * image = [[EUCImage alloc] init];
            image.filename = [EUCFileSystem fileNameForDeploymentPictureWithId:[pictureDictionary[@"id"] integerValue]];
            [self.addedImages addObject:image];
            self.numberToDownload++;
            if ([fileManager fileExistsAtPath:image.filename]) {
                self.numberDownloaded++;
                image.isLocal = YES;
            }

        }
    }
    [self.deploymentImages reloadData];

    self.downloadStatus.text = [NSString stringWithFormat:@"%ld/%ld images downloaded", self.numberDownloaded, self.numberToDownload];
    if (self.numberDownloaded < self.numberToDownload) {
        self.downloadButton.hidden = NO;
    }
}

#pragma mark - download

- (IBAction)download:(id)sender {
    // find next image to download
    if (self.numberToDownload == self.numberDownloaded) {
        self.downloadProgressView.hidden = YES;
        [self.downloadActivityIndicator stopAnimating];
        self.downloadButton.hidden = YES;
        [self refreshProgress];
        [self.deploymentImages reloadData];
        [self.bursts reloadData];
        return;
    }
    self.downloadProgressView.hidden = NO;
    self.downloadActivityIndicator.hidden = NO;
    [self.downloadActivityIndicator startAnimating];
    [self refreshProgress];
    
    // if the full-sized image is present, the thumbnail must be present
    
    for (EUCImage * image in self.burstImages) {
        if (!image.isLocal) {
            NSString * baseName = [image.filename lastPathComponent];
            NSInteger length = [baseName length];
            [EUCNetwork downloadImage:[NSString stringWithFormat:@"/file/image/%@", [[baseName substringToIndex:length - 4] substringFromIndex:1]]
                               toFile: image.filename
                           completion:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                               if (error == nil) {
                                   self.numberDownloaded++;
                                   [self refreshProgress];
                                   image.isLocal = YES;
                                   [EUCImageUtilities resizeImageAtFile:image.filename toFitWithinSize:CGSizeMake(96, 64) toFile:[self thumbnailFileNameForFile:image.filename]];
                                   [self download:nil];
                               }
                           }];
            return;
        }
    }
  
    for (EUCImage * image in self.addedImages) {
        if (!image.isLocal) {
            NSString * baseName = [image.filename lastPathComponent];
            NSInteger length = [baseName length];
            [EUCNetwork downloadImage:[NSString stringWithFormat:@"/file/deployment_picture/%@", [[baseName substringToIndex:length - 4] substringFromIndex:1]]
                               toFile: image.filename
                           completion:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                               if (error == nil) {
                                   self.numberDownloaded++;
                                   [self refreshProgress];
                                   image.isLocal = YES;
                                   [EUCImageUtilities resizeImageAtFile:image.filename toFitWithinSize:CGSizeMake(96, 64) toFile:[self thumbnailFileNameForFile:image.filename]];
                                   [self download:nil];
                               }
                           }];
            return;
        }
    }
    
}

-(void) refreshProgress {
    self.downloadProgressView.progress = self.numberDownloaded*1.0/self.numberToDownload;
    self.downloadStatus.text = [NSString stringWithFormat:@"%ld/%ld images downloaded", self.numberDownloaded, self.numberToDownload];
}


@end
