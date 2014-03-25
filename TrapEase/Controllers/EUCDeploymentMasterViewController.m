//
//  EUCDeploymentMasterViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDeploymentMasterViewController.h"
#import "EUCDeploymentCell.h"
#import "EUCNetwork.h"
#import "EUCDatabase.h"
#import "EUCDeploymentDetailViewController.h"

@interface EUCDeploymentMasterViewController ()

@end

@implementation EUCDeploymentMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.deployments = [[NSMutableArray alloc] initWithCapacity:64];
        
        [EUCNetwork getDeploymentsWithSuccessBlock:^(NSArray *deployments) {
            [[EUCDatabase sharedInstance] refreshDeployments:deployments];
            self.deployments = [[EUCDatabase sharedInstance] getDeployments];
            [self.tableView reloadData];
        } failureBlock:^(NSString *reason) {
            ; // nothing to do if we are wise, and not expecting rainbows from the skies, not right away
        }];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"EUCDeploymentMasterCell" bundle:nil] forCellReuseIdentifier:@"deploymentMasterCell"];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleAdd:(id)sender {
    [self.detailViewController clearEditView];
    self.detailViewController.editViewVisible = YES;
}

- (IBAction)handleRefresh:(id)sender {
}

- (IBAction)handleTag:(id)sender {
}

- (IBAction)handleAnalyze:(id)sender {
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [self.deployments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    EUCDeploymentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deploymentMasterCell"];
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(EUCDeploymentCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * deployment = (NSDictionary *) self.deployments[indexPath.row];
    
    cell.name.text = deployment[@"names"];
    cell.school.text = [NSString stringWithFormat:@"School %d", indexPath.row];
    cell.date.text = deployment[@"date"];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

@end
