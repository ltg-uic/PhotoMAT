//
//  EUCLabelViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUCDeploymentMasterViewController.h"

@interface EUCLabelViewController : UIViewController <SetChangedDelegate> {

    __weak IBOutlet UILabel *schoolClassGroupLabel;
}

@property(weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property(weak, nonatomic) IBOutlet UILabel *cameraLabel;
@property(weak, nonatomic) IBOutlet UIButton *animateButton;
@property(weak, nonatomic) IBOutlet UIButton *countLabel;

- (IBAction)changeCountAction:(id)sender;

@end
