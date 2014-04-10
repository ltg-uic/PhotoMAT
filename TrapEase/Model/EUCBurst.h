//
//  EUCBurst.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUCBurst : NSObject

@property (assign, nonatomic) NSInteger burstId;
@property (strong, nonatomic) NSMutableArray *images;
@property (assign, nonatomic) BOOL selected;

@end
