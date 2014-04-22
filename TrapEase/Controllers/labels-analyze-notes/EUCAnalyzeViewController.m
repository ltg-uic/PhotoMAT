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
#import "AnalyzeDatePopoverViewController.h"


@interface EUCAnalyzeViewController () <UIPopoverControllerDelegate> {
    NSMutableArray *bursts;
    NSMutableArray *analyzeItems;
    NSInteger deploymentId;
    NSDate *startDate;
    NSDate *endDate;
    EUCAppDelegate *appDelegate;
    UIPopoverController *popoverController;


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

        dateformat = [[NSDateFormatter alloc] init];
        [dateformat setDateFormat:@"hh:mm a M/d/Y"];

    }
    return self;
}

- (void)viewDidLoad {
    //[self loadData];
}

- (void)loadData {

    startDate = nil;
    endDate = nil;

    EUCDeploymentDetailViewController *burstDetailController = appDelegate.detail;
    bursts = burstDetailController.importedBursts;

    //check the date
    if (startDate == nil && endDate == nil ) {
        EUCBurst *firstBurst = [bursts firstObject];
        startDate = firstBurst.date;

        EUCBurst *lastBurst = [bursts lastObject];
        endDate = lastBurst.date;

        [self setButtonLabelDateStartDate:startDate withEndDate:endDate];
    }

    deploymentId = burstDetailController.deploymentId;

    //collect labels
    analyzeItems = [[NSMutableArray alloc] init];

    for (EUCBurst *burst in bursts) {


        NSArray *labels = [[EUCDatabase sharedInstance] labelsForBurst:burst.burstId];

        burst.labels = labels;

        NSLog(@"BURST %@", burst.date);

        if (labels != nil && labels.count > 0) {

            _errorLabel.hidden = YES;

            if (burst.labels != nil ) {
                for (EUCLabel *label in burst.labels) {

                    //see if it is
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"labelName == %@", label.name];
                    NSArray *foundObjs = [analyzeItems filteredArrayUsingPredicate:pred];

                    AnalyzeItem *analyzeItem;
                    if (foundObjs.count > 0) {
                        analyzeItem = foundObjs[0];
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
        } else {
            _errorLabel.hidden = NO;
        }
    }

    [self refreshViews];

}

- (void)refreshViews {

    if (analyzeItems != nil && analyzeItems.count > 0) {

        int y = 50;
        int offset = 90;
        for (AnalyzeItem *a in analyzeItems) {


            AnalyzeLabelUIView *labelUIView = [[AnalyzeLabelUIView alloc] init];


            [labelUIView displayAnalyzeItem:a withStartDate:startDate endDate:endDate];
            [_scrollView addSubview:labelUIView];
            CGRect newFrame = CGRectMake(6, y, labelUIView.frame.size.width, labelUIView.frame.size.width);
            labelUIView.frame = newFrame;

            y = y + offset;

        }

        float maxHeight = 0;

        for (UIView *v in [_scrollView subviews]) {
            if (v.frame.origin.x + v.frame.size.height > maxHeight)
                maxHeight = v.frame.origin.x + v.frame.size.height;
        }

        self.scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, maxHeight + 5);

    }


}

- (void)setButtonLabelDateStartDate:(NSDate *)startDate withEndDate:(NSDate *)endDate {
    [_startDateButton setTitle:[dateformat stringFromDate:startDate] forState:UIControlStateNormal];
    [_startDateButton setTitle:[dateformat stringFromDate:startDate] forState:UIControlStateHighlighted];
    [_startDateButton setTitle:[dateformat stringFromDate:startDate] forState:UIControlStateSelected];

    [_endDateButton setTitle:[dateformat stringFromDate:endDate] forState:UIControlStateNormal];
    [_endDateButton setTitle:[dateformat stringFromDate:endDate] forState:UIControlStateHighlighted];
    [_endDateButton setTitle:[dateformat stringFromDate:endDate] forState:UIControlStateSelected];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];

}

- (IBAction)showStartDatePicker:(id)sender {

    AnalyzeDatePopoverViewController *content = [[AnalyzeDatePopoverViewController alloc] initWithNibName:@"AnalyzeDatePopoverViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    //popoverController = self;
    content.somePopoverController = popoverController;

    content.datePicker.maximumDate = [endDate dateByAddingTimeInterval:-60];
    content.datePicker.date = startDate;
    content.modalInPopover = YES;
    void (^finishedHandler)(NSDate *) = ^(NSDate *newDate) {

        NSLog(@"start date button: %@", [dateformat stringFromDate:newDate]);
        startDate = newDate;
        [self changeButtonTitleWithButton:_startDateButton andStringDate:[dateformat stringFromDate:newDate]];
        [self refreshViews];

    };
    content.finishedHandler = finishedHandler;

    [popoverController setPopoverContentSize:CGSizeMake(250, 240) animated:true];
    [popoverController presentPopoverFromRect:_startDateButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


- (IBAction)showEndDatePicker:(id)sender {

    AnalyzeDatePopoverViewController *content = [[AnalyzeDatePopoverViewController alloc] initWithNibName:@"AnalyzeDatePopoverViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    //popoverController = self;
    content.somePopoverController = popoverController;

    content.datePicker.minimumDate = [startDate dateByAddingTimeInterval:+60];
    content.datePicker.date = endDate;
    content.modalInPopover = YES;
    void (^finishedHandler)(NSDate *) = ^(NSDate *newDate) {

        NSLog(@"enddate button: %@", [dateformat stringFromDate:newDate]);
        endDate = newDate;
        [self changeButtonTitleWithButton:_endDateButton andStringDate:[dateformat stringFromDate:newDate]];
        [self refreshViews];

    };
    [popoverController setPopoverContentSize:CGSizeMake(250, 240) animated:true];
    [popoverController presentPopoverFromRect:_endDateButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)changeButtonTitleWithButton:(UIButton *)button andStringDate:(NSString *)newDate {


    [button setTitle:newDate forState:UIControlStateNormal];
    [button setTitle:newDate forState:UIControlStateNormal];
    [button setTitle:newDate forState:UIControlStateHighlighted];

}


@end
