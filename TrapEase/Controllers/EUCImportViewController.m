//
//  EUCImportViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImportViewController.h"
#import "EUCImportCell.h"

#import <AssetsLibrary/AssetsLibrary.h>


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
        
        self.backgroundQueue = dispatch_queue_create("backgroundQueue", 0);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
    
    CGImageRef posterImageRef = [groupForCell posterImage];
    UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
    cell.imageView.image = posterImage;

    NSInteger numAssets = [groupForCell numberOfAssets];
    
    [groupForCell enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:numAssets - 1]
                                   options:0
                                usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                    if (result != nil && index != NSNotFound) {
                                        dispatch_async(self.backgroundQueue, ^(void) {
                                            dispatch_async(dispatch_get_main_queue(), ^(void) {
                                                UIImage * image = [UIImage imageWithCGImage:[[result defaultRepresentation] fullScreenImage]];
                                                cell.imageView.image = image;
                                            });
                                        });
                                    }
                                }];
    
    cell.label.text = [groupForCell valueForProperty:ALAssetsGroupPropertyName];

    return cell;
    
}



#pragma mark - UICollectionViewDelegate


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


@end
