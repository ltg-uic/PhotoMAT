//
//  EUCDeploymentMasterViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EUCDeploymentDetailViewController;

@interface EUCDeploymentMasterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *tagButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *analyzeButton;

@property (strong, nonatomic) NSMutableArray *deployments;


@property (strong, nonatomic) EUCDeploymentDetailViewController  *detailViewController;

- (IBAction)handleAdd:(id)sender;
- (IBAction)handleRefresh:(id)sender;
- (IBAction)handleTag:(id)sender;
- (IBAction)handleAnalyze:(id)sender;
@end
