//
//  UIUpdateDelegate.h
//  PhotoMat
//
//  Created by Anthony Perritano on 4/11/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UIUpdateDelegate <NSObject>

-(void) shouldUpdateUIWithBursts: (NSMutableArray *) bursts;

@end
