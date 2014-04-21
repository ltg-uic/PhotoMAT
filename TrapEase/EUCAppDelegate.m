//
//  EUCAppDelegate.m
//  TrapEase
//
//  Created by Aijaz Ansari on 2/25/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <OBDragDrop/OBDragDropManager.h>
#import "EUCAppDelegate.h"
#import "EUCHomeViewController.h"
#import "EUCLabelViewController.h"
#import "EUCAnalyzeViewController.h"
#import "EUCKnapsackViewController.h"
#import "EUCCloudViewController.h"
#import "EUCSettingsViewController.h"
#import "EUCDeploymentSplitViewController.h"
#import "EUCDeploymentDetailViewController.h"
#import "EUCNotesViewController.h"
#import "EUCUserViewController.h"

#import "EUCDatabase.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"

#import "EUCConnectingViewController.h"
#import "EUCNetwork.h"
#import "EUCTabBarViewControllerDelegate.h"
#import "EUCFileSystem.h"

@interface EUCAppDelegate () {
}

@property(strong, nonatomic) EUCTabBarViewControllerDelegate *tabBarVCDelegate;

@end

@implementation EUCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];


    /*
     ** ********************************************************************
     ** LOGGING START
     ** ********************************************************************
     */
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    fileLogger.maximumFileSize = 1024 * 1024;

    [DDLog addLogger:fileLogger];
#ifdef DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif
    /*
     ** ********************************************************************
     ** LOGGING END
     ** ********************************************************************
     */

    [EUCFileSystem makeImageDirIfNecessary]; // make image directory

    // initialize network with person id
    EUCDatabase *db = [EUCDatabase sharedInstance];
    NSDictionary *dbSettings = db.settings;
    [EUCNetwork updatePersonId:dbSettings[@"personId"]];


    EUCCloudViewController *cloud = [[EUCCloudViewController alloc] initWithNibName:@"EUCCloudViewController" bundle:nil];
    EUCNotesViewController *notes = [[EUCNotesViewController alloc] initWithNibName:@"EUCNotesViewController" bundle:nil];
    EUCSettingsViewController *settings = [[EUCSettingsViewController alloc] initWithNibName:@"EUCSettingsViewController" bundle:nil];
    EUCDeploymentSplitViewController *dsvc = [[EUCDeploymentSplitViewController alloc] init];
    EUCDeploymentMasterViewController *master = [[EUCDeploymentMasterViewController alloc] initWithNibName:@"EUCDeploymentMasterViewController" bundle:nil];
    self.detail = [[EUCDeploymentDetailViewController alloc] initWithNibName:@"EUCDeploymentDetailViewController" bundle:nil];
    EUCLabelViewController *label = [[EUCLabelViewController alloc] initWithNibName:@"EUCLabelViewController" bundle:nil];
    EUCAnalyzeViewController *analyze = [[EUCAnalyzeViewController alloc] initWithNibName:@"EUCAnalyzeViewController" bundle:nil];
    EUCUserViewController *user = [[EUCUserViewController alloc] initWithNibName:@"EUCUserViewController" bundle:nil];
    EUCKnapsackViewController *snapshot = [[EUCKnapsackViewController alloc] initWithNibName:@"EUCKnapsackViewController" bundle:nil asSnapshot:YES];
    EUCKnapsackViewController *photos = [[EUCKnapsackViewController alloc] initWithNibName:@"EUCKnapsackViewController" bundle:nil asSnapshot:NO];

    master.detailViewController = self.detail;
    master.setChangedDelegate = label;
    self.detail.master = master;

    dsvc.viewControllers = @[master, self.detail];

    self.homeViewController = [[EUCHomeViewController alloc] init];
    self.homeViewController.viewControllers = @[user, dsvc, label, analyze, notes, cloud, snapshot, photos];
    //label, analyze, settings,

    [[[[self.homeViewController.tabBarController tabBar] items] objectAtIndex:2] setEnabled:NO];
    [[[[self.homeViewController.tabBarController tabBar] items] objectAtIndex:3] setEnabled:NO];
    self.tabBarVCDelegate = [[EUCTabBarViewControllerDelegate alloc] init];
    self.tabBarVCDelegate.snapshot = snapshot;
    self.tabBarVCDelegate.photos = photos;
    self.tabBarVCDelegate.analyze = analyze;
    self.tabBarVCDelegate.label = label;
    self.homeViewController.delegate = self.tabBarVCDelegate;
    self.tabBarVCDelegate.window = self.window;
    master.setSelectedDelegate = self.tabBarVCDelegate;

    // check to see if you have school data

    if ([db hasSchools]) {
        self.window.rootViewController = self.homeViewController;
    }
    else {
        EUCConnectingViewController *connect = [[EUCConnectingViewController alloc] initWithNibName:@"EUCConnectingViewController" bundle:nil];
        self.window.rootViewController = connect;
    }

    OBDragDropManager *manager = [OBDragDropManager sharedManager];
    [manager prepareOverlayWindowUsingMainWindow:self.window];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
