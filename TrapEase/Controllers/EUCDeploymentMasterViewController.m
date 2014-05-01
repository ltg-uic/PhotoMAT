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
        self.selectedStatusBySetId = [NSMutableDictionary dictionaryWithCapacity:64];
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
    cell.setId = [deployment[@"id"] integerValue];
    cell.master = self;
    
    NSInteger setId = [deployment[@"id"] integerValue];
    NSLog(@"setId in configure is %ld", (long) setId);
    
    BOOL cellSelected = [self.selectedStatusBySetId[@(setId)] boolValue];
    
    if (cellSelected) {
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
//        cell.name.backgroundColor = [UIColor redColor];
    }
    else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
//        cell.name.backgroundColor = [UIColor blackColor];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *deployment = (NSDictionary *) self.deployments[indexPath.row];
    
    NSInteger setId = [deployment[@"id"] integerValue];
    BOOL cellSelected = NO;
    if (self.selectedStatusBySetId[@(setId)] == nil) {
        self.selectedStatusBySetId[@(setId)] = @YES;
        cellSelected = YES;
    }
    else if ([self.selectedStatusBySetId[@(setId)] isEqual:@(NO)]) {
        self.selectedStatusBySetId[@(setId)] = @YES;
        cellSelected = YES;
    }
    else if ([self.selectedStatusBySetId[@(setId)] isEqual:@(YES)]) {
        self.selectedStatusBySetId[@(setId)] = @NO;
        cellSelected = NO;
    }
    
    EUCDeploymentCell * cell = (EUCDeploymentCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if (cellSelected) {
        cell.contentView.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
    }
    else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    NSInteger numSelected = [self numberOfSelectedSets];
    NSLog(@"NumSelected = %ld", (long) numSelected);

    if (numSelected == 1) {
        NSSet * set = [self selectedSets];
        setId = [[set anyObject] integerValue];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@", @(setId)];

        NSDictionary *deployment = (NSDictionary *) [self.deployments filteredArrayUsingPredicate: pred][0];

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
        
        [self.detailViewController setupForSingle];
    }
    else {
        [self.detailViewController setupForMultiple];
    }
    
    [self.tableView reloadData];
}


#pragma mark - selected sets

-(NSInteger)numberOfSelectedSets {
    NSSet *resultSet = [self selectedSets];
    return [resultSet count];
}

-(NSSet *) selectedSets {
    return [self.selectedStatusBySetId keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return [obj isEqual:@YES];
    }];
    
}

// todo: write this
-(NSArray *) namesOfSelectedSets {
    NSSet * selectedSets = [self selectedSets];
    
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:[self.deployments count]];
    
    for (NSDictionary * deployment in self.deployments) {
        if ([selectedSets containsObject:deployment[@"id"]]) {
            [result addObject:[NSString stringWithFormat:@"%@ : %@ : %@ : %@", deployment[@"school_name"],
                              deployment[@"class_name"],
                              deployment[@"person_name"],
                               deployment[@"short_name"]]];
        }
    }
    return [NSArray arrayWithArray:result];
}

-(NSArray *)burstsForSelectedSets {
    EUCDatabase * db = [EUCDatabase sharedInstance];
    return [db getBurstsForDeploymentsWithIds:[self selectedSets]];
}

@end
