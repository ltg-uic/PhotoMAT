//
//  EUCTabBarViewControllerDelegate.h
//  TrapEase
//
//  Created by Aijaz Ansari on 4/7/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUCDeploymentMasterViewController.h"

@interface EUCTabBarViewControllerDelegate : NSObject <UITabBarControllerDelegate, SetChangedDelegate>
@property (weak, nonatomic) UIViewController *snapshot;
@property (weak, nonatomic) UIViewController *photos;
@property (weak, nonatomic) UIWindow *window;
@property (weak, nonatomic) UIViewController *analyze;
@property (weak, nonatomic) UIViewController *label;
@end
