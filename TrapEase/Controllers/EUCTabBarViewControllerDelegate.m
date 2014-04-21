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
#import "EUCNetwork.h"
#import "EUCTimeUtilities.h"
#import "Toast+UIView.h"


static BOOL DEV = NO;

@interface EUCTabBarViewControllerDelegate () {
}
@property(assign, nonatomic) BOOL setSelected;
@property (strong, nonatomic) UIImage *screenshotImage;
@property (strong, nonatomic) UIView *toastView;

@end


@implementation EUCTabBarViewControllerDelegate



#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
//    if (viewController == self.snapshot) {
//        UIImage * image = [EUCImageUtilities snapshotForWindow:self.window];
//        EUCKnapsackViewController * snapshot = (EUCKnapsackViewController *) self.snapshot;
//        snapshot.imageView.image = image;
//        return YES;
//    }
//    else {
//        return YES;
//    }
    EUCDatabase *db = [EUCDatabase sharedInstance];
    NSDictionary *settings = db.settings;
    if ([settings[@"personId"] isEqualToNumber:@0]) {
        return NO;
    }

    if (viewController == self.snapshot
            &&
            (tabBarController.selectedViewController != self.snapshot)
            ) {
        UIImage *image = [EUCImageUtilities snapshotForWindow:self.window];
//        EUCKnapsackViewController *snapshot = (EUCKnapsackViewController *) self.snapshot;
//        snapshot.imageView.image = image;
//        snapshot.savedImage = image;
        self.screenshotImage = image;
        [self save:nil];
        
        return NO;
    }
    if (viewController == self.analyze ||
            viewController == self.label) {
        return self.setSelected;
    }

    return YES;
}

#pragma mark - SetChangedDelegate 
- (void)currentDeploymentIdSetTo:(NSInteger)deploymentId {
    self.setSelected = YES;
}


- (void)save:(id)sender {
    // get the backpack
    
    
    EUCDatabase * db = [EUCDatabase sharedInstance];
    NSString * className = [db className];
    NSString * groupName = [db groupName];
    
    NSString * backpackURL;
    NSDictionary * selector = @{@"selector": [NSString stringWithFormat:@"{\"owner\": \"%@\"}", groupName]};
    if (DEV) {
        backpackURL = [NSString stringWithFormat:@"http://drowsy.badger.encorelab.org/dev-safari-%@/backpacks", className];
    }
    else {
        backpackURL = [NSString stringWithFormat:@"http://drowsy.badger.encorelab.org/safari-%@/backpacks", className];
    }
    
    NSString * repoURL = @"http://pikachu.badger.encorelab.org/";
    __block NSData * data;
    
    void (^restBlock)() = ^{
        [EUCNetwork uploadImageData:data toRepo:repoURL completion:^(NSString *payloadURL, NSString *errorCode) {
            if (errorCode) {
                [self alertWithTitle:@"Error" message:errorCode];
                [self activityStopped];
            }
            else {
                NSLog(@"URL Is %@", payloadURL);
                
                // get backpack(backpackurl)
                // if backpack is empty
                //    create backpack(url)
                // else
                //    add to content
                // PUT to backpack url

                [EUCNetwork getBackpack:backpackURL
                           withSelector: selector
                       withSuccessBlock:^(NSArray *objects) {
                           if ([objects count]) {
                               // backpack exists
                               // extract dictionary
                               NSDictionary * robackpack = (NSDictionary *)[objects firstObject];
                               NSMutableDictionary * backpack = [[NSMutableDictionary alloc] init];
                               NSDictionary * _id = robackpack[@"_id"];
                               NSString * oid = _id[@"$oid"];
                               
                               backpack[@"_id"] = _id;
                               backpack[@"owner"] = robackpack[@"owner"];
                               
                               NSMutableArray * contents = [NSMutableArray arrayWithArray: robackpack[@"content"]];
                               backpack[@"content"] = contents;
                               
                               [contents addObject:[self backpackEntryForUrl:payloadURL]];
                               NSString * putURL = [NSString stringWithFormat:@"%@/%@", backpackURL, oid];
                               
                               [EUCNetwork putBackpack:backpack
                                                 toUrl:putURL
                                          successBlock:^(NSURLSessionDataTask *task, id responseObject) {
                                              [self alertWithTitle:@"Success" message:@"The picture has been added to your backpack"];
                                              [self activityStopped];
                                          } failureBlock:^(NSURLSessionDataTask *task, NSError *error) {
                                              [self alertWithTitle:@"Error" message:[error localizedDescription]];
                                              [self activityStopped];
                                          }];
                           }
                           else {
                               // create backpack dictionary
                               NSMutableDictionary * backpack = [[NSMutableDictionary alloc] init];
                               backpack[@"owner"] = groupName;
                               NSMutableArray * contents = [NSMutableArray arrayWithCapacity:1];
                               [contents addObject:[self backpackEntryForUrl:payloadURL]];
                               backpack[@"content"] = contents;
                               
                               [EUCNetwork postBackpack:backpack
                                                  toUrl:backpackURL
                                           successBlock:^(AFHTTPRequestOperation *operation, id responseObject) {
                                               NSLog(@"Got %@", responseObject);
                                               [self alertWithTitle:@"Success" message:@"The picture has been added to your backpack"];
                                               [self activityStopped];
                                           } failureBlock:^(AFHTTPRequestOperation *operation, NSError *error) {
                                               [self alertWithTitle:@"Error" message:[error localizedDescription]];
                                               [self activityStopped];
                                           }];
                               
                           }
                       }
                           failureBlock:^(NSString *reason) {
                               [self alertWithTitle:@"Error" message:reason];
                               [self activityStopped];
                               
                           }];
            }
        }];
    };
    
    if (self.screenshotImage) {
        [self.window makeToastActivity];
        data = UIImageJPEGRepresentation(self.screenshotImage, 1.0);
        restBlock();
    }
    
    
    
    
}

-(void) activityStopped {
    [self.window hideToastActivity];
}

-(void) alertWithTitle: (NSString *) title message: (NSString *) message {
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles: nil];
    
    [alertView show];
}

-(NSDictionary *) backpackEntryForUrl: (NSString *) url {
    return @{@"item_type": @"photomat_image",
             @"image_url": [NSString stringWithFormat:@"http://pikachu.badger.encorelab.org/%@", url],
             @"created_at": [EUCTimeUtilities currentTimeInZulu]
             };
}




@end
