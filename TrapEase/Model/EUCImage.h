//
//  EUCAsset.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUCImage : NSObject

- (instancetype)initWithIndex: (NSInteger) index andUrl: (NSURL *) url;
- (instancetype)initWithIndex: (NSInteger) index andFilename: (NSString *) filename;

@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) NSURL * url;
@property (strong, nonatomic) NSDate *assetDate;
@property (assign, nonatomic) CGSize dimensions;
@property (strong, nonatomic) NSString *filename;



@end
