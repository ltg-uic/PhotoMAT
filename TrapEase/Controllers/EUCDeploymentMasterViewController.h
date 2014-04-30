//
//  EUCDeploymentMasterViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUCVisibilityChangedDelegate.h"

@protocol SetChangedDelegate <NSObject>

- (void)currentDeploymentIdSetTo:(NSInteger)deploymentId;

@end

@class EUCDeploymentDetailViewController;

@interface EUCDeploymentMasterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property(weak, nonatomic) IBOutlet UITableView *tableView;

@property(strong, nonatomic) NSArray *deployments;

@property (strong, nonatomic) NSMutableDictionary * selectedStatusBySetId;


@property(strong, nonatomic) EUCDeploymentDetailViewController *detailViewController;
@property(weak, nonatomic) id <SetChangedDelegate> setChangedDelegate;
@property(weak, nonatomic) id <SetChangedDelegate> setSelectedDelegate;

- (IBAction)handleAdd:(id)sender;

- (IBAction)handleRefresh:(id)sender;

-(NSInteger) numberOfSelectedSets;
-(NSSet *) selectedSets;



@end
