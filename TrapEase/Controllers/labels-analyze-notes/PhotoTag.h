//
// Created by Anthony Perritano on 4/7/14.
// Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TagView;


@interface PhotoTag : NSObject

@property(nonatomic, strong) TagView *tagView;
@property(nonatomic, strong) NSString *imageName;
@property(nonatomic) CGFloat xPosition;
@property(nonatomic) CGFloat yPosition;

@end