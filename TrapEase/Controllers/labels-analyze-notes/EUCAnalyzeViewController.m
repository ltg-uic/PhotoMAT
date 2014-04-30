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
#import "TimelineUIViewController.h"
#import "EUCDeploymentMasterViewController.h"


@interface EUCAnalyzeViewController () <UIPopoverControllerDelegate> {
    NSArray *bursts;
    NSMutableArray *analyzeItems;
    NSInteger deploymentId;
    NSDate *startDate;
    NSDate *endDate;
    NSDate *orginalStartDate;
    NSDate *orginalEndDate;
    EUCAppDelegate *appDelegate;
    UIPopoverController *popoverController;
    UIPopoverController *errorPopoverController;

    NSDateFormatter *dateformat;


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
    [self.view addSubview:_completeTimelineView];
    //[self loadData];
}

- (void)loadData {

    NSArray *subviews = [_completeTimelineView subviews];

    for (UIView *v in subviews) {
        [v removeFromSuperview];
    }

    startDate = nil;
    endDate = nil;

    EUCDeploymentDetailViewController *burstDetailController = appDelegate.detail;
    bursts = [burstDetailController.master burstsForSelectedSets];

    //check the date
    if (startDate == nil && endDate == nil ) {
        EUCBurst *firstBurst = [bursts firstObject];
        startDate = firstBurst.date;
        orginalStartDate = firstBurst.date;
        EUCBurst *lastBurst = [bursts lastObject];
        endDate = lastBurst.date;
        orginalEndDate = lastBurst.date;

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

                        if (analyzeItem != nil && index >= 0) {
                            [analyzeItems replaceObjectAtIndex:index withObject:analyzeItem];
                        }


                    } else {
                        analyzeItem = [[AnalyzeItem alloc] init];
                        analyzeItem.labelName = label.name;
                        [analyzeItem addBurst:burst];
                        [analyzeItems addObject:analyzeItem];
                    }

                }
            }

        }

    }
    [self refreshViews];


}

- (void)displayLabeling:(BOOL)shouldShow {
    _startDateButton.hidden = !shouldShow;
    _endDateButton.hidden = !shouldShow;
    _timelineLabel.hidden = !shouldShow;
    _countLabel.hidden = !shouldShow;
    _labelLabel.hidden = !shouldShow;
    _startTimeLabel.hidden = !shouldShow;
    _endTimeLabel.hidden = !shouldShow;
}

- (void)refreshViews {


    NSArray *subviews = [_completeTimelineView subviews];

    for (UIView *v in subviews) {
        [v removeFromSuperview];
    }

    if (analyzeItems != nil && analyzeItems.count > 0) {


        int y = 0;
        int offset = 47;


        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"labelName" ascending:YES];
        [analyzeItems sortUsingDescriptors:[NSArray arrayWithObject:sort]];


        for (AnalyzeItem *a in analyzeItems) {


            AnalyzeLabelUIView *labelUIView = [[AnalyzeLabelUIView alloc] init];


            [labelUIView displayAnalyzeItem:a withStartDate:startDate endDate:endDate];
            CGRect newFrame = CGRectMake(5, y, labelUIView.frame.size.width, labelUIView.frame.size.width);
            labelUIView.frame = newFrame;
            UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            pgr.maximumNumberOfTouches = 1;
            [labelUIView.timeliveView addGestureRecognizer:pgr];
            [_completeTimelineView addSubview:labelUIView];


            y = y + offset;

        }

        [self displayLabeling:YES];
        _errorLabel.hidden = YES;
        [self.view setNeedsDisplay];

    } else {
        [self displayLabeling:NO];
        _errorLabel.hidden = NO;
        [self.view setNeedsDisplay];
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
    content.orginalDate = orginalStartDate;
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
    content.orginalDate = orginalEndDate;
    content.datePicker.date = endDate;
    content.modalInPopover = YES;
    void (^finishedHandler)(NSDate *) = ^(NSDate *newDate) {

        NSLog(@"enddate button: %@", [dateformat stringFromDate:newDate]);
        endDate = newDate;
        [self changeButtonTitleWithButton:_endDateButton andStringDate:[dateformat stringFromDate:newDate]];
        [self refreshViews];

    };
    content.finishedHandler = finishedHandler;
    [popoverController setPopoverContentSize:CGSizeMake(250, 240) animated:true];
    [popoverController presentPopoverFromRect:_endDateButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)changeButtonTitleWithButton:(UIButton *)button andStringDate:(NSString *)newDate {
    [button setTitle:newDate forState:UIControlStateNormal];
    [button setTitle:newDate forState:UIControlStateNormal];
    [button setTitle:newDate forState:UIControlStateHighlighted];
}


- (void)enableImageViewGesturesOnTimelineView:(UIView *)timelineView {
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [timelineView addGestureRecognizer:pgr];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {


    static CGRect originalFrame;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        // CGPoint translate = [gesture translationInView:gesture.view.superview];
        CGPoint translate = [gesture locationInView:gesture.view];
        TimelineUIViewController *content = [[TimelineUIViewController alloc] initWithNibName:@"TimelineUIViewController" bundle:nil];


        errorPopoverController = [[UIPopoverController alloc]
                initWithContentViewController:content];

        content.modalInPopover = YES;
        // content.messageLabel.text = @"hello";

        TimelineView *timelineView = (TimelineView *) gesture.view;

        NSString *touchDate = [timelineView getDateForTouchPointXY:CGPointMake(translate.x, translate.y) withStartDate:startDate];

        content.dateLabel.text = touchDate;
        [errorPopoverController setPopoverContentSize:CGSizeMake(196, 35) animated:true];
        [errorPopoverController presentPopoverFromRect:CGRectMake(translate.x, translate.y, 1, 1) inView:gesture.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];

    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        // CGPoint translate = [gesture translationInView:gesture.view.superview];
        CGPoint translate = [gesture locationInView:gesture.view];

        TimelineView *timelineView = (TimelineView *) gesture.view;

        TimelineUIViewController *content = errorPopoverController.contentViewController;
        NSString *touchDate = [timelineView getDateForTouchPointXY:CGPointMake(translate.x, translate.y) withStartDate:startDate];

        content.dateLabel.text = touchDate;

        [errorPopoverController presentPopoverFromRect:CGRectMake(translate.x, translate.y, 1, 1) inView:gesture.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];


    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"JOY");
        [errorPopoverController dismissPopoverAnimated:true];
    } else if (gesture.state == UIGestureRecognizerStateCancelled) {
        NSLog(@"LOL");
    }
}

@end
