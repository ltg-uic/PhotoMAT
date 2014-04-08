//
//  EUCTabBarViewControllerDelegate.h
//  TrapEase
//
//  Created by Aijaz Ansari on 4/7/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUCTabBarViewControllerDelegate : NSObject <UITabBarControllerDelegate>
@property (weak, nonatomic) UIViewController *snapshot;
@property (weak, nonatomic) UIViewController *photos;
@property (weak, nonatomic) UIWindow *window;

@end
