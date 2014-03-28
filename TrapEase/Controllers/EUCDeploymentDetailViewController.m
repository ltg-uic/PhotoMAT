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


CGFloat defaultDeploymentWideness = 96.0/64.0;


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
@property (strong, nonatomic) NSMutableArray *importedBursts;
@property (strong, nonatomic) NSMutableArray *addedImages;
@property (strong, nonatomic) NSMutableArray *burstImages;
@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;

@property (assign, nonatomic) BOOL hasLibrary;
@property (assign, nonatomic) BOOL hasCamera;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIPopoverController *popover;



- (IBAction)addImage:(id)sender;
- (IBAction)addBursts:(id)sender;
- (IBAction)done:(id)sender;

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
    
    
    self.addBurstsButton.hidden = self.isEdit;
    self.doneButton.hidden = !self.isEdit;
    
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
    
    for (EUCBurst * burst in self.importedBursts) {
        for (EUCImage * image in burst.images) {
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

- (IBAction)addImage:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Source", @"selectSource")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  nil];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Camera", @"Camera")];
        self.hasCamera = YES;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Photo Library", @"Photo Library")];
        self.hasLibrary = YES;
    }
    
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [actionSheet showFromRect:[(UIButton *)sender frame] inView:self.view animated:YES];

}

- (IBAction)addBursts:(id)sender {
    EUCImportViewController * import = [[EUCImportViewController alloc] initWithNibName:@"EUCImportViewController" bundle:nil];
    import.importDoneDelegate = self;
    [self presentViewController:import animated:YES completion:nil];
}

- (IBAction)done:(id)sender {
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
    
    EUCImage * burstImage;
    if (collectionView == self.bursts) {
        burstImage = self.burstImages[indexPath.row];
    }
    else {
        burstImage = self.addedImages[indexPath.row];
    }
    
    [self.assetsLibrary assetForURL:burstImage.url resultBlock:^(ALAsset *asset) {
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
//    UIImage * image = [self blurredSnapshot];
//    
//    EUCSelectViewController * selectViewController = [[EUCSelectViewController alloc] initWithNibName:@"EUCSelectViewController" bundle:nil assetGroup:(ALAssetsGroup *) self.groups[indexPath.row] image:image];
//    selectViewController.selectionDoneDelegate = self;
//    
//    [self presentViewController:selectViewController animated:NO completion:nil];
}



#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
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

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Picking Image from Camera/ Library
    [self.popover dismissPopoverAnimated:YES];
    UIImage * selectedImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    
    if (!selectedImage)
    {
        return;
    }
    
//    NSTimeInterval seconds = NSTimeIntervalSince1970;
//    
//    NSString * fileName = [NSString stringWithFormat:@"local_%f.jpg", seconds];
//    NSURL *documentsDirectoryURL = [NSURL URLWithString:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
//    NSString * filePath = [documentsDirectoryURL path];
//    NSString * fullPath = [filePath stringByAppendingPathComponent:fileName];
    
    //    // via http://ios-funda.blogspot.com/2013/03/uiactionsheet-example.html
    //    // Adjusting Image Orientation
//    NSData *data = UIImageJPEGRepresentation(selectedImage, 1.0);
//    UIImage *tmp = [UIImage imageWithData:data];
//    UIImage *fixed = [UIImage imageWithCGImage:tmp.CGImage
//                                         scale:0.5f
//                                   orientation:selectedImage.imageOrientation];
//    selectedImage = fixed;
    
//    [UIImageJPEGRepresentation(selectedImage, 1.0) writeToFile:fullPath atomically:NO];
//    EUCDeploymentImage * image = [[EUCDeploymentImage alloc] init];
    
    [self.assetsLibrary writeImageToSavedPhotosAlbum:selectedImage.CGImage
                                 metadata:[info objectForKey:UIImagePickerControllerMediaMetadata]
                          completionBlock:^(NSURL *assetURL, NSError *error) {
                              EUCImage * image = [[EUCImage alloc] initWithIndex:0 andUrl:assetURL];
                              [self.addedImages addObject:image];
                              [self.deploymentImages reloadData];
                          }];
    
//    image.fileName = filePath;
//    [self.addedImages addObject:image];
    
//    self.completionBlock(fileName);
    
    
}


@end
