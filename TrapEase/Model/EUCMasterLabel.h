//
//  EUCMasterLabel.h
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/17/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUCMasterLabel : NSObject

@property (assign, nonatomic) NSInteger masterLabelID;
@property (assign, nonatomic) NSInteger deploymentID;
@property (strong, nonatomic) NSString *name;

@end
