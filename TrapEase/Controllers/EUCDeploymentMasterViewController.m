//
//  EUCDeploymentMasterViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDeploymentMasterViewController.h"
#import "EUCDeploymentCell.h"

@interface EUCDeploymentMasterViewController ()

@end

@implementation EUCDeploymentMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.deployments = [[NSMutableArray alloc] initWithCapacity:64];
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
    cell.name.text = [NSString stringWithFormat:@"Name %d", indexPath.row];
    cell.school.text = [NSString stringWithFormat:@"School %d", indexPath.row];
    cell.date.text = [NSString stringWithFormat:@"Date %d", indexPath.row];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

@end
