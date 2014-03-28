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



@end
