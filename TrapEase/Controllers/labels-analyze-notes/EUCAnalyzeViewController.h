//
//  EUCAnalyzeViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EUCAnalyzeViewController : UIViewController {
}
@property(weak, nonatomic) IBOutlet UILabel *errorLabel;
@property(weak, nonatomic) IBOutlet UIButton *startDateButton;
@property(weak, nonatomic) IBOutlet UIButton *endDateButton;
@property(weak, nonatomic) IBOutlet UIView *completeTimelineView;
@property(weak, nonatomic) IBOutlet UILabel *timelineLabel;
@property(weak, nonatomic) IBOutlet UILabel *countLabel;
@property(weak, nonatomic) IBOutlet UILabel *labelLabel;
@property(weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property(weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property(weak, nonatomic) IBOutlet UIButton *setNamesButton;
@property(weak, nonatomic) IBOutlet UILabel *startRangeLabel;
@property(weak, nonatomic) IBOutlet UIButton *startRangeButton;
@property(weak, nonatomic) IBOutlet UILabel *endRangeLabel;
@property(weak, nonatomic) IBOutlet UIButton *endRangeButton;
@property(weak, nonatomic) IBOutlet UILabel *analysisPeriodLabel;
@property(weak, nonatomic) IBOutlet UILabel *dailyWindowLabel;


- (IBAction)showStartDatePicker:(id)sender;

- (IBAction)showEndDatePicker:(id)sender;

- (IBAction)showSetNamesPopover:(id)sender;

@end
