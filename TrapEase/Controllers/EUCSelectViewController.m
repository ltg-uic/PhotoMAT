//
//  EUCSelectViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCSelectViewController.h"
#import "EUCSelectCell.h"

extern CGFloat defaultWideness;

@interface EUCSelectViewController ()

@property (strong, nonatomic) dispatch_queue_t backgroundQueue;
- (IBAction)done:(id)sender;
@property (strong, nonatomic) NSMutableArray *bursts; // array of arrays of images
@property (strong, nonatomic) NSMutableArray *currentBurstSubIndexes;

@property (strong, nonatomic) NSMutableArray *selected;

@end

@implementation EUCSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil assetGroup: (ALAssetsGroup *) group image: (UIImage *) image
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);//dispatch_queue_create("backgroundQueue", 0);
        _group = group;
        _selected = [[NSMutableArray alloc] initWithCapacity:[_group numberOfAssets]];
        for (NSInteger i = 0; i < [_group numberOfAssets]; i++) {
            [_selected addObject:@YES];
        }
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
    
    NSTimeInterval burstDelta = 60;
    
    [self.group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset != nil) {
            if (burstIndex == -1) {
                burstIndex++;
                burstSubIndex++;
                [self.bursts addObject:[NSMutableArray arrayWithArray:@[@(index)]]];
                lastDate = [asset valueForProperty:ALAssetPropertyDate];
            }
            else {
                // most of the code happens here
                NSDate * thisAssetsDate = [asset valueForProperty:ALAssetPropertyDate];
                NSTimeInterval delta = [thisAssetsDate timeIntervalSinceDate:lastDate];
                if (abs(delta) < burstDelta) {
                    burstSubIndex++;
                    [self.bursts[burstIndex] addObject:@(index)];
                    lastDate = [asset valueForProperty:ALAssetPropertyDate];
                }
                else {
                    burstIndex++;
                    [self.bursts addObject:[NSMutableArray arrayWithArray:@[@(index)]]];
                    burstSubIndex = 0;
                    lastDate = [asset valueForProperty:ALAssetPropertyDate];
                }
            }
        }
    }];
    
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
    NSInteger assetIndex = [self.bursts[indexPath.row][subIndex] integerValue];
    NSLog(@"subIndex is %ld and assetIndex is %ld out of total %ld", subIndex, assetIndex, [self.group numberOfAssets]);
    
    [self.group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:assetIndex]
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
                                              cell.indexPath = indexPath;
                                              cell.parentViewController = self;
                                              [self configureSelectedForCell: cell atIndexPath:indexPath];
                                              
                                          });
                                      });
                                  }
                              }];
}

-(void) configureSelectedForCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath {
    if ([self.selected[indexPath.row] isEqual:@NO]) {
        cell.mask.hidden = NO;
        CGRect f = CGRectMake((cell.imageView.frame.size.width - cell.imageView.image.size.width)/2,
                              (cell.imageView.frame.size.height - cell.imageView.image.size.height),
                              cell.imageView.image.size.width,
                              cell.imageView.image.size.height);
        cell.mask.frame = f;
        
        [cell.button setImage:[UIImage imageNamed:@"thumbs-down.png"] forState:UIControlStateNormal];
    }
    else {
        cell.mask.hidden = YES;
        [cell.button setImage:[UIImage imageNamed:@"thumbs-up.png"] forState:UIControlStateNormal];
    }
}

-(void) toggleCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath {
    if ([self.selected[indexPath.row] isEqual:@NO]) {
        self.selected[indexPath.row] = @YES;
    }
    else {
        self.selected[indexPath.row] = @NO;
    }
    [self configureSelectedForCell: cell atIndexPath:indexPath];
}

#pragma mark - CollectionViewDelegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    EUCSelectCell * cell = (EUCSelectCell *)[collectionView cellForItemAtIndexPath:indexPath];
//    [self toggleCell:cell atIndexPath:indexPath];
    
    NSInteger count = [self.bursts[indexPath.row] count];
    if (count == 1) {
        return; // no toggling here
    }
    
    NSInteger currentSubIndex = [self.currentBurstSubIndexes[indexPath.row] integerValue];
    currentSubIndex++;
    
    if (currentSubIndex >= count) {
        currentSubIndex = 0;
    }
    self.currentBurstSubIndexes[indexPath.row] = @(currentSubIndex);

    EUCSelectCell * cell = (EUCSelectCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];

}

#pragma mark - FlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(314, 274);
}


- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

@end
