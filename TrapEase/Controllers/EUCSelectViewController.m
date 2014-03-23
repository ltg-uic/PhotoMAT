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

@property (strong, nonatomic) NSMutableArray *selected;

@end

@implementation EUCSelectViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil assetGroup: (ALAssetsGroup *) group
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EUCSelectCell" bundle:nil] forCellWithReuseIdentifier:@"selectCell"];
    
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
    return [self.group numberOfAssets];
}

-(EUCSelectCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCSelectCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"selectCell" forIndexPath:indexPath];

    [self.group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:indexPath.row]
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
    
    return cell;
}

-(void) configureSelectedForCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath {
    if ([self.selected[indexPath.row] isEqual:@NO]) {
        cell.mask.hidden = NO;
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

#pragma mark - FlowLayoutDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(314, 274);
}


- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
