//
//  EUCDeploymentMasterViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDeploymentMasterViewController.h"
#import "EUCDeploymentCell.h"
#import "EUCDatabase.h"
#import "EUCDeploymentDetailViewController.h"
#import "EUCSelectedSet.h"

@interface EUCDeploymentMasterViewController ()
@end

@implementation EUCDeploymentMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.deployments = [[NSMutableArray alloc] initWithCapacity:64];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.tableView registerNib:[UINib nibWithNibName:@"EUCDeploymentMasterCell" bundle:nil] forCellReuseIdentifier:@"deploymentMasterCell"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self handleRefresh:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleAdd:(id)sender {
//    [self.detailViewController clearEditView];
//    self.detailViewController.editViewVisible = YES;
    EUCDeploymentDetailViewController *detail = [[EUCDeploymentDetailViewController alloc] initWithNibName:@"EUCDeploymentDetailViewController" bundle:nil];
    detail.editViewVisible = YES;
    detail.updateMode = NO;
    detail.master = self;
    detail.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:detail animated:YES completion:nil];
}

- (IBAction)handleRefresh:(id)sender {
    self.deployments = [[EUCDatabase sharedInstance] getDeployments];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [self.deployments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EUCDeploymentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deploymentMasterCell"];

    [self configureCell:cell forRowAtIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(EUCDeploymentCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *deployment = (NSDictionary *) self.deployments[indexPath.row];

    cell.name.text = [NSString stringWithFormat:@"%@ - %@", deployment[@"person_name"], deployment[@"short_name"]];
    cell.school.text = [NSString stringWithFormat:@"%@, %@", deployment[@"school_name"], deployment[@"class_name"]];
    cell.date.text = deployment[@"date"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *deployment = (NSDictionary *) self.deployments[indexPath.row];

    self.detailViewController.editViewVisible = YES;
    self.detailViewController.updateMode = YES;

    EUCSelectedSet *selected = [EUCSelectedSet sharedInstance];
    selected.schoolName = deployment[@"school_name"];
    selected.className = deployment[@"class_name"];
    selected.groupName = deployment[@"person_name"];
    selected.deploymentName = deployment[@"short_name"];
    NSNumber *ownerId = deployment[@"person_id"];
    selected.ownerId = [ownerId integerValue];


    [self.detailViewController loadDeployment:deployment[@"id"]];
    NSNumber *depId = deployment[@"id"];
    [self.setChangedDelegate currentDeploymentIdSetTo:[depId integerValue]];
    [self.setSelectedDelegate currentDeploymentIdSetTo:[depId integerValue]];
}


@end
