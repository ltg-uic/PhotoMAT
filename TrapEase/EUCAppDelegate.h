//
//  EUCAppDelegate.h
//  TrapEase
//
//  Created by Aijaz Ansari on 2/25/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EUCHomeViewController;
@class EUCDeploymentDetailViewController;

@interface EUCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) EUCHomeViewController *homeViewController;
@property (strong, nonatomic) EUCDeploymentDetailViewController * detail;


@end
