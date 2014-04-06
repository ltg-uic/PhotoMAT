//
//  EUCSelectViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol EUCSelectionDoneDelegate <NSObject>

-(void) selectionDone: (NSMutableArray *) bursts;

@end

@class EUCSelectCell;

@interface EUCSelectViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) ALAssetsGroup *group;
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) id<EUCSelectionDoneDelegate> selectionDoneDelegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil assetGroup: (ALAssetsGroup *) group image: (UIImage *) image;
//-(void) configureSelectedForCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath;
-(void) toggleCell: (EUCSelectCell *) cell atIndexPath:(NSIndexPath *) indexPath;


@end
