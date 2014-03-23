//
//  EUCImportViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImportViewController.h"
#import "EUCImportCell.h"
#import "UIImage+ImageEffects.h"
#import "EUCSelectViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

CGFloat defaultWideness = 314.0/226.0;

@interface EUCImportViewController ()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) NSMutableArray * groups;
@property (strong, nonatomic) dispatch_queue_t backgroundQueue;

@end

@implementation EUCImportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Import", "Import")
                                                        image:[UIImage imageNamed:@"download.png"]
                                                selectedImage:nil];
        
        self.backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//dispatch_queue_create("backgroundQueue", 0);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.automaticallyAdjustsScrollViewInsets = NO;

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EUCImportCell" bundle:nil] forCellWithReuseIdentifier:@"importCell"];
    
    
    if (self.assetsLibrary == nil) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    if (self.groups == nil) {
        self.groups = [[NSMutableArray alloc] init];
    } else {
        [self.groups removeAllObjects];
    }
    
    // setup our failure view controller in case enumerateGroupsWithTypes fails
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        
        NSString *errorMessage = nil;
        switch ([error code]) {
            case ALAssetsLibraryAccessUserDeniedError:
            case ALAssetsLibraryAccessGloballyDeniedError:
                errorMessage = @"You have declined access to it. Please grant access from the Settings App.";
                break;
            default:
                errorMessage = @"Reason unknown.";
                break;
        }
        
        UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Can't Access Photos"
                                                             message:errorMessage
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil];
        
        [alertView show];
    };
    
    // emumerate through our groups and only add groups that contain photos
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
        [group setAssetsFilter:onlyPhotosFilter];
        if ([group numberOfAssets] > 0)
        {
            [self.groups addObject:group];
        }
        else
        {
            [self.collectionView reloadData];
        }
    };
    
    // enumerate only photos
    NSUInteger groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos;
    [self.assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:listGroupBlock failureBlock:failureBlock];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

#pragma mark - UICollectionViewDataSource


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.groups count];
    
}


-(EUCImportCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCImportCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"importCell" forIndexPath:indexPath];

    ALAssetsGroup *groupForCell = self.groups[indexPath.row];
    [groupForCell setAssetsFilter:[ALAssetsFilter allPhotos]];
    
    NSInteger numAssets = [groupForCell numberOfAssets];
    
    [groupForCell enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:numAssets - 1]
                                   options:0
                                usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                    if (result != nil && index != NSNotFound) {
                                        dispatch_async(self.backgroundQueue, ^(void) {
                                            dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                UIImage * image = [UIImage imageWithCGImage:[result aspectRatioThumbnail]];
                                                CGFloat wideness = 1.0*image.size.width/image.size.height;
                                                CGSize size;

                                                if (wideness > defaultWideness) {
                                                    size.width = 314;
                                                    // width - height
                                                    // 314
                                                    size.height = 314/wideness;
                                                }
                                                else {
                                                    size.height = 226;
                                                    // width - height
                                                    //         226
                                                    size.width = 226 * wideness;
                                                }
                                                UIImage * resizedImage = [self imageWithImage:image scaledToSize:size];
                                                cell.imageView.image = resizedImage;
                                            });
                                        });
                                    }
                                }];
    
    cell.label.text = [groupForCell valueForProperty:ALAssetsGroupPropertyName];

    return cell;
    
}



#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UIImage * image = [self blurredSnapshot];
    
    EUCSelectViewController * selectViewController = [[EUCSelectViewController alloc] initWithNibName:@"EUCSelectViewController" bundle:nil assetGroup:(ALAssetsGroup *) self.groups[indexPath.row] image:image];
    
//    EUCBlurSelectViewController * blurSelectViewController = [[EUCBlurSelectViewController alloc] initWithNibName:@"EUCBlurSelectViewController" bundle:nil];
//    blurSelectViewController.image = image;
    
    [self presentViewController:selectViewController animated:NO completion:nil];
}


#pragma mark - FlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(314, 226);
}


#pragma mark - Image Size

- (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - blurring

// from http://damir.me/ios7-blurring-techniques
-(UIImage *)blurredSnapshot
{
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(self.view.window.bounds.size, NO, self.view.window.screen.scale);
    
    // There he is! The new API method
    [self.view.window drawViewHierarchyInRect:self.view.window.frame afterScreenUpdates:NO];
    
    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    
    // Now apply the blur effect using Apple's UIImageEffect category
    UIImage *blurredSnapshotImage = [snapshotImage applyLightEffect];
    
    // Or apply any other effects available in "UIImage+ImageEffects.h"
    // UIImage *blurredSnapshotImage = [snapshotImage applyDarkEffect];
    // UIImage *blurredSnapshotImage = [snapshotImage applyExtraLightEffect];
    
    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
//    CGFloat scaleValue = 1.0;
    
//    CGRect subRect = CGRectMake(0, 0, self.view.window.frame.size.width / scaleValue, self.view.window.frame.size.height / scaleValue);
//    CGImageRef subImage = CGImageCreateWithImageInRect(blurredSnapshotImage.CGImage, subRect);
//    UIImage *backgroundImage = [UIImage imageWithCGImage:subImage];
//    CGImageRelease(subImage);
    
    
    // return blurredSnapshotImage;
    return [self scaleAndRotateImage:blurredSnapshotImage];
}

// from http://stackoverflow.com/a/3526833/772526
- (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 2048; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    
    boundHeight = bounds.size.height;
    bounds.size.height = bounds.size.width;
    bounds.size.width = boundHeight;
    transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width/2.0);
    
    transform = CGAffineTransformRotate(transform, M_PI / 2.0);
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIImageOrientation orient = image.imageOrientation;
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -264-height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    UIInterfaceOrientation sbOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (sbOrientation == UIInterfaceOrientationLandscapeLeft) {
        return [self rotateUIImage:imageCopy];
    }
    return imageCopy;
}

// from http://stackoverflow.com/a/20004215/772526
- (UIImage*)rotateUIImage:(UIImage*)sourceImage
{
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(size);
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:1.0 orientation:UIImageOrientationDown] drawInRect:CGRectMake(0,0,size.width ,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


@end
