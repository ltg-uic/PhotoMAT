//
//  EUCDeploymentMasterViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUCVisibilityChangedDelegate.h"

@class EUCDeploymentDetailViewController;

@interface EUCDeploymentMasterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, EUCVisibilityChangedDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *deployments;


@property (strong, nonatomic) EUCDeploymentDetailViewController  *detailViewController;

- (IBAction)handleAdd:(id)sender;
- (IBAction)handleRefresh:(id)sender;
@end
