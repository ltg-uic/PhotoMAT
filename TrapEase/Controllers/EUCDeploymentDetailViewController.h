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
@property (assign, nonatomic) BOOL isEdit;

-(void) clearEditView;

@end
