//
//  EUCSelectedSet.h
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/10/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EUCSelectedSet : NSObject

@property (strong, nonatomic) NSString *schoolName;
@property (strong, nonatomic) NSString *className;
@property (strong, nonatomic) NSString *groupName;
@property (strong, nonatomic) NSString *deploymentName;
@property (assign, nonatomic) NSInteger ownerId;

+(EUCSelectedSet *) sharedInstance;

@end
