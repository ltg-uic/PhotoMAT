//
//  EUCUserViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/25/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUCVisibilityChangedDelegate.h"

@protocol EUCLoginChangedDelegate <NSObject>

-(void) loginDidChangeToSchool: (NSString *) schoolName;

@end

@interface EUCUserViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) id<EUCVisibilityChangedDelegate> visibilityDelegate;
@property (weak, nonatomic) id<EUCLoginChangedDelegate> loginChangedDelegate;

@end
