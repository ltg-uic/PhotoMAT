//
//  EUCSelectViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCSelectViewController.h"
#import "EUCSelectCell.h"
#import "EUCBurst.h"
#import "EUCImage.h"

extern CGFloat defaultWideness;


@interface EUCSelectViewController ()

@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
- (IBAction)done:(id)sender;
@property (strong, nonatomic) NSMutableArray *bursts; // array of arrays of images
@property (strong, nonatomic) NSMutableArray *currentBurstSubIndexes;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSArray *sortedArrayOfImages;

- (IBAction)selectAll:(id)sender;
- (IBAction)unselectAll:(id)sender;
- (IBAction)cancel:(id)sender;
@end

@implementation EUCSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil assetGroup: (ALAssetsGroup *) group image: (UIImage *) image
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//dispatch_queue_create("backgroundQueue", 0);
        _group = group;
        _image = image;
        [self createBurstGroups];
    }
    return self;
}

-(void) createBurstGroups {
    self.bursts = [[NSMutableArray alloc] init];

    // each item in the array of arrays is an index of the asset
    
    __block NSInteger burstIndex = -1;
    __block NSInteger burstSubIndex = -1;
    __block NSDate * lastDate;
    
    NSTimeInterval burstDelta = 20;
    
    NSMutableArray * unsortedArray = [NSMutableArray arrayWithCapacity:64];

    [self.group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset != nil) {
            [unsortedArray addObject:asset];
        }
    }];
    
    self.sortedArrayOfImages = [unsortedArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        ALAsset * first = (ALAsset *) a;
        ALAsset * second = (ALAsset *) b;
        NSDate * firstDate = [first valueForProperty:ALAssetPropertyDate];
        NSDate * secondDate = [second valueForProperty:ALAssetPropertyDate];
        return [firstDate compare:secondDate];
    }];

    NSUInteger index = 0;
    for (ALAsset * asset in self.sortedArrayOfImages) {
        if (asset != nil) {
            if (burstIndex == -1) {
                burstIndex++;
                burstSubIndex++;
                EUCBurst * burst = [[EUCBurst alloc] init];
                burst.selected = NO;
                EUCImage * image = [[EUCImage alloc] initWithIndex:index andAsset:asset];
                [self.bursts addObject:burst];
                [burst.images addObject:image];
                
                lastDate = image.assetDate;
            }
            else {
                // most of the code happens here
                NSDate * thisAssetsDate = [asset valueForProperty:ALAssetPropertyDate];
                NSTimeInterval delta = [thisAssetsDate timeIntervalSinceDate:lastDate];
                if (abs(delta) < burstDelta) {
                    burstSubIndex++;
                    EUCBurst * burst = self.bursts[burstIndex];
                    burst.selected = NO;
                    EUCImage * image = [[EUCImage alloc] initWithIndex:index andAsset:asset];
                    [burst.images addObject:image];
                    lastDate = image.assetDate;
                }
                else {
                    burstIndex++;
                    EUCBurst * newBurst = [[EUCBurst alloc] init];
                    newBurst.selected = NO;
                    EUCImage * image = [[EUCImage alloc] initWithIndex:index andAsset:asset];
                    [self.bursts addObject:newBurst];
                    [newBurst.images addObject:image];
                    burstSubIndex = 0;
                    lastDate = image.assetDate;
                }
            }
            index++;
        }
        
    }
    
    self.currentBurstSubIndexes = [NSMutableArray arrayWithCapacity:[self.bursts count]];  // contains subIndexes
    for (NSInteger i = 0; i < [self.bursts count]; i++) {
        [self.currentBurstSubIndexes addObject:@(0)];
    }
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EUCSelectCell" bundle:nil] forCellWithReuseIdentifier:@"selectCell"];
    
    self.imageView.image = self.image;
    
    self.activityIndicator.hidden = YES;
    
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


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CollectionViewDataSource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // return [self.group numberOfAssets];
    return [self.bursts count];
}

-(EUCSelectCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCSelectCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"selectCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


-(void) configureCell: (EUCSelectCell *) cell atIndexPath: (NSIndexPath *) indexPath {
    NSInteger subIndex = [self.currentBurstSubIndexes[indexPath.row] integerValue];
    EUCBurst * burst = self.bursts[indexPath.row];
    EUCImage * image = burst.images[subIndex];
    NSInteger assetIndex = image.index;
    
    ALAsset * asset = self.sortedArrayOfImages[assetIndex];
    dispatch_async(self.backgroundQueue, ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            UIImage * image = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
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
            cell.indexPath = indexPath;
            cell.parentViewController = self;
            [self configureSelectedForCell: cell atIndexPath:indexPath];
            
        });
    });
}

-(void) configureSelectedForCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath {
    EUCBurst * burst = self.bursts[indexPath.row];
    if (burst.selected == NO) {
        cell.mask.hidden = YES;
        
        [cell.button setImage:[UIImage imageNamed:@"thumbs-down.png"] forState:UIControlStateNormal];
    }
    else {
        cell.mask.hidden = YES;
        [cell.button setImage:[UIImage imageNamed:@"thumbs-up.png"] forState:UIControlStateNormal];
    }
}

-(void) toggleCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath {
    EUCBurst * burst = self.bursts[indexPath.row];
    burst.selected = !(burst.selected);
    [self configureSelectedForCell: cell atIndexPath:indexPath];
}

#pragma mark - CollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCBurst * burst = self.bursts[indexPath.row];
    NSInteger numImagesInBurst = [burst.images count];
    if (numImagesInBurst == 1) {
        return; // no toggling here
    }
    
    NSInteger currentSubIndex = [self.currentBurstSubIndexes[indexPath.row] integerValue];
    currentSubIndex++;
    
    if (currentSubIndex >= numImagesInBurst) {
        currentSubIndex = 0;
    }
    self.currentBurstSubIndexes[indexPath.row] = @(currentSubIndex);

    EUCSelectCell * cell = (EUCSelectCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];

}

#pragma mark - FlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(314, 314);
}


- (IBAction)done:(id)sender {
    NSMutableArray * selectedBursts = [NSMutableArray arrayWithCapacity:[self.bursts count]];
    
    [self.bursts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        EUCBurst * burst = (EUCBurst *) obj;
        if (burst.selected) {
            [selectedBursts addObject:burst];
        }
    }];
    [self.selectionDoneDelegate selectionDone:selectedBursts];
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)selectAll:(id)sender {
    NSInteger row = 0;
    NSIndexPath * indexPath;
    NSDate * d1 = [NSDate date];
    for (EUCBurst * burst in self.bursts) {
        burst.selected = YES;
        indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        EUCSelectCell * cell = (EUCSelectCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        row++;
        [self configureSelectedForCell:cell atIndexPath:indexPath];
    }
    NSLog(@"diff %ld", (long)[d1 timeIntervalSinceNow] * -1);

}

- (IBAction)unselectAll:(id)sender {
    NSInteger row = 0;
    NSIndexPath * indexPath;
    NSDate * d1 = [NSDate date];
    for (EUCBurst * burst in self.bursts) {
        burst.selected = NO;
        indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        EUCSelectCell * cell = (EUCSelectCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        row++;
        [self configureSelectedForCell:cell atIndexPath:indexPath];
    }
    NSLog(@"diff %ld", (long)[d1 timeIntervalSinceNow] * -1);
}

- (IBAction)cancel:(id)sender {
    [self unselectAll:sender];
    [self done:sender];
}
@end
