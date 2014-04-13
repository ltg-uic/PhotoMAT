//
//  EUCImageUtilities.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUCImageUtilities : NSObject

+(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;
+(UIImage *)blurredSnapshotForWindow: (UIWindow *) window;
+(UIImage *)scaleAndRotateImage:(UIImage *)image;
+(UIImage*)rotateUIImage:(UIImage*)sourceImage;

+(UIImage *)snapshotForWindow: (UIWindow *) window;
+(UIImage *)snapshotForView: (UIView *) view;
+(void) resizeImageAtFile: (NSString *) source toSize: (CGSize) newSize toFile: (NSString *) destination;
+(void) resizeImageAtFile: (NSString *) source toFitWithinSize: (CGSize) newSize toFile: (NSString *) destination;

@end
