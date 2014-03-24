//
//  EUCDeploymentsViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCDeploymentsViewController.h"
#import "EUCDeploymentCell.h"

@interface EUCDeploymentsViewController ()

@end

@implementation EUCDeploymentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Deployments", "Deployments")
                                                        image:[UIImage imageNamed:@"deployments"]
                                                selectedImage:nil];
        
        self.deployments = [[NSMutableArray alloc] initWithCapacity:64];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EUCDeploymentCell" bundle:nil] forCellWithReuseIdentifier:@"deploymentCell"];
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) refresh {
}

#pragma mark - collectionViewDataSource

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.deployments count];
}

-(EUCDeploymentCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCDeploymentCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"deploymentCell" forIndexPath:indexPath];
    
    NSDictionary * deployment = self.deployments[indexPath.row];
    
    cell.name.text = deployment[@"names"];
    cell.date.text = deployment[@"date"];
    cell.school.text = deployment[@"school"];
    
    return cell;
    
}



#pragma mark - collectionViewDelegate



@end
