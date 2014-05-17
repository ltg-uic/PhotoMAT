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
#import "SetNameContentViewController.h"
#import "DDPopoverBackgroundView.h"


@interface EUCAnalyzeViewController () <UIPopoverControllerDelegate, UIPickerViewDelegate> {
    NSArray *bursts;
    NSMutableArray *analyzeItems;
    NSInteger deploymentId;
    NSDate *startDate;
    NSDate *endDate;
    NSDate *orginalStartDate;
    NSDate *orginalEndDate;

    NSDate *periodEndDate;
    NSDate *periodStartDate;

    EUCAppDelegate *appDelegate;
    UIPopoverController *popoverController;
    UIPopoverController *errorPopoverController;

    NSDateFormatter *dateformat;
    NSDateFormatter *periodDateformat;
    NSArray *namesOfSelectedSets;

    int isNextDay;
}
@end

@implementation EUCAnalyzeViewController {
}

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


        periodDateformat = [[NSDateFormatter alloc] init];
        [periodDateformat setDateFormat:@"hh:mm a"];

    }
    return self;
}

- (void)viewDidLoad {
    [self.view addSubview:_completeTimelineView];
    //[self loadData];

    [_daySelector addTarget:self action:@selector(dayChanged:) forControlEvents:UIControlEventValueChanged];

}

- (void)dayChanged:(id)dayChanged {

    //0 is sameday
    //1 nextday
    int whichDay = _daySelector.selectedSegmentIndex;

    if (whichDay == 1) {

        NSDate *startWindow = [periodDateformat dateFromString:_startRangeButton.currentTitle];
        NSDate *endWindow = [periodDateformat dateFromString:_endRangeButton.currentTitle];


        if ([endWindow timeIntervalSinceDate:startWindow] > 0) {

            [self changeButtonTitleWithButton:_startRangeButton andStringDate:[periodDateformat stringFromDate:startWindow]];

            [self changeButtonTitleWithButton:_endRangeButton andStringDate:[periodDateformat stringFromDate:startWindow]];

            periodEndDate = startWindow;

            [self refreshViews];
        }


    } else {

        NSDate *startWindow = [periodDateformat dateFromString:_startRangeButton.currentTitle];
        NSDate *endWindow = [periodDateformat dateFromString:_endRangeButton.currentTitle];


        if ([endWindow timeIntervalSinceDate:startWindow] < 0) {


            NSCalendar *calendar = [NSCalendar currentCalendar];

            NSDateComponents *tempStartComps = [[NSDateComponents alloc] init];

            [tempStartComps setHour:23];
            [tempStartComps setMinute:59];
            [tempStartComps setSecond:59];

            NSDate *midnight = [calendar dateFromComponents:tempStartComps];


            [self changeButtonTitleWithButton:_startRangeButton andStringDate:[periodDateformat stringFromDate:startWindow]];

            [self changeButtonTitleWithButton:_endRangeButton andStringDate:[periodDateformat stringFromDate:midnight]];

            periodEndDate = startWindow;

            [self refreshViews];
        }


    }

}

- (void)checkTimes {


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
    namesOfSelectedSets = [burstDetailController.master namesOfSelectedSets];


    //check the date
    if (startDate == nil && endDate == nil ) {
        EUCBurst *firstBurst = [bursts firstObject];
        startDate = firstBurst.date;
        orginalStartDate = firstBurst.date;

        EUCBurst *lastBurst;
        if (bursts.count == 1) {

            endDate = [startDate dateByAddingTimeInterval:SECONDS_IN_DAY];
            orginalEndDate = endDate;
        } else {
            lastBurst = [bursts lastObject];
            endDate = lastBurst.date;
            orginalEndDate = lastBurst.date;
        }


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
    _setNamesButton.hidden = !shouldShow;
    _startRangeLabel.hidden = !shouldShow;
    _startRangeButton.hidden = !shouldShow;
    _endRangeLabel.hidden = !shouldShow;
    _endRangeButton.hidden = !shouldShow;
    _analysisPeriodLabel.hidden = !shouldShow;
    _dailyWindowLabel.hidden = !shouldShow;
    _periodDayLabel.hidden = !shouldShow;
    _daySelector.hidden = !shouldShow;
    //[self displaySetNames];
}

- (void)displaySetNames {

    if (namesOfSelectedSets.count > 0) {
        NSString *firstName = [namesOfSelectedSets firstObject];

        NSString *names;

        if (namesOfSelectedSets.count > 1) {
            names = [firstName stringByAppendingFormat:@" . . . "];
        }

        [_setNamesButton setTitle:names forState:UIControlStateNormal];
        [_setNamesButton setTitle:names forState:UIControlStateNormal];
        [_setNamesButton setTitle:names forState:UIControlStateHighlighted];

    }
}


- (void)refreshViews {


    NSArray *subviews = [_completeTimelineView subviews];

    for (UIView *v in subviews) {
        [v removeFromSuperview];
    }

    if (analyzeItems != nil && analyzeItems.count > 0) {

        //period buttons
        periodStartDate = [periodDateformat dateFromString:_startRangeButton.currentTitle];
        periodEndDate = [periodDateformat dateFromString:_endRangeButton.currentTitle];


        NSInteger isNextDay = _daySelector.selectedSegmentIndex;
        if (isNextDay == 1) {
            periodEndDate = [periodEndDate dateByAddingTimeInterval:86400];
        }

        int y = 0;
        int offset = 47;


        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"labelName" ascending:YES];
        [analyzeItems sortUsingDescriptors:[NSArray arrayWithObject:sort]];


        for (AnalyzeItem *a in analyzeItems) {


            AnalyzeLabelUIView *labelUIView = [[AnalyzeLabelUIView alloc] init];


            [labelUIView displayAnalyzeItem:a withStartDate:startDate withEndDate:endDate withStartPeriod:periodStartDate withEndPeriod:periodEndDate];
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

- (void)setButtonLabelDateStartPeriod:(NSDate *)startDate withEndPeriod:(NSDate *)endDate {
    [_startRangeButton setTitle:[dateformat stringFromDate:startDate] forState:UIControlStateNormal];
    [_startRangeButton setTitle:[dateformat stringFromDate:startDate] forState:UIControlStateHighlighted];
    [_startRangeButton setTitle:[dateformat stringFromDate:startDate] forState:UIControlStateSelected];

    [_endRangeButton setTitle:[dateformat stringFromDate:endDate] forState:UIControlStateNormal];
    [_endRangeButton setTitle:[dateformat stringFromDate:endDate] forState:UIControlStateHighlighted];
    [_endRangeButton setTitle:[dateformat stringFromDate:endDate] forState:UIControlStateSelected];

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


- (IBAction)showStartPeriodPickerPopover:(id)sender {


    AnalyzeDatePopoverViewController *content = [[AnalyzeDatePopoverViewController alloc] initWithNibName:@"AnalyzeDatePopoverViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];


    content.somePopoverController = popoverController;

    content.dateformat.dateFormat = periodDateformat;

//    NSInteger isNextDay = _daySelector.selectedSegmentIndex;
//    if(isNextDay == 1) {
//        content.datePicker.minimumDate = [periodEndDate dateByAddingTimeInterval:-86400];
//    } else {
//        content.datePicker.maximumDate  = [periodEndDate dateByAddingTimeInterval:-60];
//    }

    content.datePicker.date = [periodDateformat dateFromString:_startRangeButton.titleLabel.text];
    content.orginalDate = periodStartDate;
    content.datePicker.datePickerMode = UIDatePickerModeTime;
    content.modalInPopover = YES;
    void (^finishedHandler)(NSDate *) = ^(NSDate *newDate) {

        periodStartDate = newDate;
        [self changeButtonTitleWithButton:_startRangeButton andStringDate:[periodDateformat stringFromDate:newDate]];

        [self dayChanged:nil];

    };
    content.finishedHandler = finishedHandler;
    [popoverController setPopoverContentSize:CGSizeMake(250, 240) animated:true];
    [popoverController presentPopoverFromRect:_startRangeButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)whichSelected:(id)sender {

    [self refreshViews];
}

- (IBAction)showEndPeriodPickerPopover:(id)sender {

    AnalyzeDatePopoverViewController *content = [[AnalyzeDatePopoverViewController alloc] initWithNibName:@"AnalyzeDatePopoverViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];


    content.somePopoverController = popoverController;

    content.dateformat.dateFormat = periodDateformat;

    NSInteger isNextDay = _daySelector.selectedSegmentIndex;
    if (isNextDay == 1) {
        content.isNextDay = YES;
    } else {
        content.isNextDay = NO;
        content.datePicker.minimumDate = [periodStartDate dateByAddingTimeInterval:+60];
    }

    content.startPeriodDate = periodStartDate;
    content.datePicker.date = [periodDateformat dateFromString:_endRangeButton.titleLabel.text];
    content.orginalDate = periodEndDate;
    content.datePicker.datePickerMode = UIDatePickerModeTime;
    content.modalInPopover = YES;
    void (^finishedHandler)(NSDate *) = ^(NSDate *newDate) {

        periodEndDate = newDate;
        [self changeButtonTitleWithButton:_endRangeButton andStringDate:[periodDateformat stringFromDate:newDate]];
        [self refreshViews];

    };
    content.finishedHandler = finishedHandler;
    [popoverController setPopoverContentSize:CGSizeMake(250, 240) animated:true];
    [popoverController presentPopoverFromRect:_endRangeButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


- (IBAction)showSetNamesPopover:(id)sender {

    SetNameContentViewController *content = [[SetNameContentViewController alloc] initWithNibName:@"SetNameContentViewController" bundle:nil];


    errorPopoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    EUCDeploymentDetailViewController *burstDetailController = appDelegate.detail;
    namesOfSelectedSets = [burstDetailController.master namesOfSelectedSets];
    NSString *firstName = [namesOfSelectedSets firstObject];

    NSString *names;
    for (NSString *name in namesOfSelectedSets) {
        if ([name isEqualToString:firstName]) {
            names = firstName;
        } else {
            names = [names stringByAppendingFormat:@"\n%@", name];
        }
    }
    content.textView.text = names;
    //content.textView.backgroundColor =  [UIColor clearColor];

    //content.textView.alpha = .2f;
    // errorPopoverController.backgroundColor =  [UIColor clearColor];

    [errorPopoverController setPopoverBackgroundViewClass:[DDPopoverBackgroundView class]];
    [DDPopoverBackgroundView setShadowEnabled:YES];
    [DDPopoverBackgroundView setTintColor:[UIColor colorWithRed:127 green:127 blue:127 alpha:.5]];


    [errorPopoverController setPopoverContentSize:CGSizeMake(300, 190) animated:true];
    [errorPopoverController presentPopoverFromRect:_setNamesButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];


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
