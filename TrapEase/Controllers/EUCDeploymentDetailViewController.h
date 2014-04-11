//
//  EUCDeploymentDetailViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/24/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUCImportViewController.h"
#import "EUCDatePickerViewController.h"


@interface EUCDeploymentDetailViewController : UIViewController <EUCImportDoneDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, EUCDatePickerDelegate>

@property (weak, nonatomic) IBOutlet UIView *editView;


@property (assign, nonatomic) BOOL editViewVisible;
@property (assign, nonatomic) BOOL updateMode;


@property (readonly, nonatomic) NSDate *nominalDate;
@property (readonly, nonatomic) NSDate *actualDate;
@property (readonly, nonatomic) NSMutableArray *importedBursts;
@property (readonly, nonatomic) NSMutableArray *addedImages;
@property (readonly, nonatomic) NSMutableArray *burstImages;


-(void) clearEditView;
-(void) loadDeployment: (NSNumber *) deploymentId;


@end
