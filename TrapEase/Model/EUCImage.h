//
//  EUCAsset.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface EUCImage : NSObject

- (instancetype)initWithIndex: (NSInteger) index andUrl: (NSURL *) url;
- (instancetype)initWithIndex: (NSInteger) index andAsset: (ALAsset *) asset;

@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) NSURL * url;
@property (strong, nonatomic) NSDate *assetDate;
@property (assign, nonatomic) CGSize dimensions;
@property (strong, nonatomic) NSString *filename;
@property (strong, nonatomic) NSURL * thumbnailURL;
@property (assign, nonatomic) BOOL isLocal;



@end
