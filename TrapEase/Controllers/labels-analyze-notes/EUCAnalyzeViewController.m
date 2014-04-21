//
//  EUCAnalyzeViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCAnalyzeViewController.h"
#import "EUCDeploymentDetailViewController.h"
#import "EUCDatabase.h"
#import "EUCBurst.h"
#import "EUCLabel.h"
#import "EUCAppDelegate.h"
#import "AnalyzeItem.h"
#import "AnalyzeLabelUIView.h"


@interface EUCAnalyzeViewController () {
    NSMutableArray *bursts;
    NSMutableArray *analyzeItems;
    NSInteger deploymentId;
    NSDate *startDate;
    NSDate *endDate;
    EUCAppDelegate *appDelegate;


}
@end

@implementation EUCAnalyzeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Analyze", "Analyze")
                                                        image:[UIImage imageNamed:@"line-chart"]
                                                selectedImage:nil];
        appDelegate = (EUCAppDelegate *) [[UIApplication sharedApplication] delegate];

    }
    return self;
}

- (void)viewDidLoad {


    [self loadData];


}

- (void)loadData {

    EUCDeploymentDetailViewController *burstDetailController = appDelegate.detail;
    bursts = burstDetailController.importedBursts;


    deploymentId = burstDetailController.deploymentId;

    //collect labels
    analyzeItems = [[NSMutableArray alloc] init];

    for (EUCBurst *burst in bursts) {


        NSArray *labels = [[EUCDatabase sharedInstance] labelsForBurst:burst.burstId];

        burst.labels = labels;
        //check the date
        if (startDate != nil ) {
            //The receiver is later in time than anotherDate, NSOrderedDescending
            if (([startDate compare:burst.date]) == NSOrderedDescending) {
                startDate = burst.date;
            }
        } else {
            startDate = burst.date;
        }

        if (endDate != nil ) {
            if (([endDate compare:burst.date]) == NSOrderedAscending) {
                endDate = burst.date;
            }
        } else {
            //The receiver is earlier in time than anotherDate, NSOrderedAscending
            endDate = burst.date;
        }

        if (burst.labels != nil ) {
            for (EUCLabel *label in burst.labels) {

                //see if it is
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"labelName == %@", label.name];
                NSArray *foundObjs = [analyzeItems filteredArrayUsingPredicate:pred];

                AnalyzeItem *analyzeItem;
                if (foundObjs.count > 0) {
                    analyzeItem = foundObjs[0];
                    analyzeItem.labelName = label.name;
                    [analyzeItem addBurst:burst];
                    int index = [analyzeItems indexOfObject:analyzeItem];
                    [analyzeItems replaceObjectAtIndex:index withObject:analyzeItem];
                } else {
                    analyzeItem = [[AnalyzeItem alloc] init];
                    analyzeItem.labelName = label.name;
                    [analyzeItem addBurst:burst];
                    [analyzeItems addObject:analyzeItem];
                }

            }
        }
    }


    if (analyzeItems != nil && analyzeItems.count > 0) {

        int y = 50;
        int offset = 47;
        for (AnalyzeItem *a in analyzeItems) {


            AnalyzeLabelUIView *labelUIView = [[AnalyzeLabelUIView alloc] init];


            [labelUIView displayAnalyzeItem:a withStartDate:startDate endDate:endDate];
            [self.view addSubview:labelUIView];
            CGRect newFrame = CGRectMake(6, y, labelUIView.frame.size.width, labelUIView.frame.size.width);
            labelUIView.frame = newFrame;

            y = y + offset;

        }

    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];

}

@end
