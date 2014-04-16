//
//  EUCLabel.h
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/15/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EUCBurst;
@interface EUCLabel : NSObject

@property (assign, nonatomic) NSInteger labelId;
@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) CGPoint location;



@end
