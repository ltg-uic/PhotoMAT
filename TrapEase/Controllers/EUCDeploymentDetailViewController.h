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
#import "GPUCameraViewController.h"

@class EUCDeploymentMasterViewController;

@interface EUCDeploymentDetailViewController : UIViewController <EUCImportDoneDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, EUCDatePickerDelegate, GPUImageCameraDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *editView;
@property (weak, nonatomic) EUCDeploymentMasterViewController * master;


@property (assign, nonatomic) BOOL editViewVisible;
@property (assign, nonatomic) BOOL updateMode;


@property (readonly, nonatomic) NSDate *nominalDate;
@property (readonly, nonatomic) NSDate *actualDate;
@property (readonly, nonatomic) NSMutableArray *importedBursts;
@property (readonly, nonatomic) NSMutableArray *addedImages;
@property (readonly, nonatomic) NSMutableArray *burstImages;
@property (assign, nonatomic) NSInteger deploymentId;

-(void) clearEditView;
-(void) loadDeployment: (NSNumber *) deploymentId;


@end
