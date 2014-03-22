//
//  EUCImportViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImportViewController.h"
#import "EUCImportCell.h"

@interface EUCImportViewController ()
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (assign, nonatomic) NSInteger numAlbums;
@property (assign, nonatomic) NSArray * albums;

@end

@implementation EUCImportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Import", "Import")
                                                        image:[UIImage imageNamed:@"download.png"]
                                                selectedImage:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EUCImportCell" bundle:nil] forCellWithReuseIdentifier:@"importCell"];
    
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

#pragma mark - UICollectionViewDataSource


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.albums count];
    
}


-(EUCImportCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EUCImportCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"importCell" forIndexPath:indexPath];

    return cell;
    
}

#pragma mark - UICollectionViewDelegate


@end
