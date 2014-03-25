//
//  EUCDeploymentDetailViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/24/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EUCDeploymentDetailViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *editView;


@property (assign, nonatomic) BOOL editViewVisible;
@property (assign, nonatomic) BOOL isEdit;

-(void) clearEditView;

@end
