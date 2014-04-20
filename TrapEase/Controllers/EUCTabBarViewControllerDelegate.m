//
//  EUCTabBarViewControllerDelegate.m
//  TrapEase
//
//  Created by Aijaz Ansari on 4/7/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCTabBarViewControllerDelegate.h"
#import "EUCImageUtilities.h"
#import "EUCKnapsackViewController.h"
#import "EUCDatabase.h"

@interface EUCTabBarViewControllerDelegate () {}
@property (assign, nonatomic) BOOL setSelected;

@end


@implementation EUCTabBarViewControllerDelegate 



#pragma mark - UITabBarControllerDelegate

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
//    if (viewController == self.snapshot) {
//        UIImage * image = [EUCImageUtilities snapshotForWindow:self.window];
//        EUCKnapsackViewController * snapshot = (EUCKnapsackViewController *) self.snapshot;
//        snapshot.imageView.image = image;
//        return YES;
//    }
//    else {
//        return YES;
//    }
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSDictionary * settings = db.settings;
    if ([settings[@"personId"] isEqualToNumber:@0]) {
        return NO;
    }
    
    if (viewController == self.snapshot
        &&
        (tabBarController.selectedViewController != self.snapshot)
        ) {
        UIImage * image = [EUCImageUtilities snapshotForWindow:self.window];
        EUCKnapsackViewController * snapshot = (EUCKnapsackViewController *) self.snapshot;
        snapshot.imageView.image = image;
        snapshot.savedImage = image;
    }
    if (viewController == self.analyze ||
        viewController == self.label) {
        return self.setSelected;
    }

    return YES;
}

#pragma mark - SetChangedDelegate 
-(void)currentDeploymentIdSetTo:(NSInteger)deploymentId {
    self.setSelected = YES;
}
@end
