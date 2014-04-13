//
//  EUCImageUtilities.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCImageUtilities.h"
#import "UIImage+ImageEffects.h"

@implementation EUCImageUtilities


+(UIImage *)snapshotForView: (UIView *) view
{
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 1.0);
    
    // There he is! The new API method
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    
    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    
    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
    
    // return blurredSnapshotImage;
    return [EUCImageUtilities scaleAndRotateImage:snapshotImage];
}



+(UIImage *)snapshotForWindow: (UIWindow *) window
{
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, window.screen.scale);
    
    // There he is! The new API method
    [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
    
    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    
    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
    
    // return blurredSnapshotImage;
    return [EUCImageUtilities scaleAndRotateImage:snapshotImage];
}


#pragma mark - Image Size

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(void)resizeImageAtFile:(NSString *)source toSize:(CGSize)newSize toFile:(NSString *)destination {
    UIImage * sourceImage = [UIImage imageWithContentsOfFile:source];
    UIImage * destImage = [EUCImageUtilities imageWithImage:sourceImage scaledToSize:newSize];
    NSData * destData = UIImageJPEGRepresentation(destImage, 1.0);
    [destData writeToFile:destination atomically:YES];
}

+(void) resizeImageAtFile: (NSString *) source toFitWithinSize: (CGSize) maxSize toFile: (NSString *) destination {
    UIImage * sourceImage = [UIImage imageWithContentsOfFile:source];
    CGSize origSize = sourceImage.size;
    CGFloat defaultWideness = maxSize.width*1.0/maxSize.height;
    
    CGFloat wideness = 1.0*origSize.width/origSize.height;
    CGSize newSize;
    if (wideness > defaultWideness) {
        newSize.width = maxSize.width;
        newSize.height = maxSize.width/wideness;
    }
    else {
        newSize.height = maxSize.height;
        newSize.width = maxSize.height * wideness;
    }
    
    
    UIImage * destImage = [EUCImageUtilities imageWithImage:sourceImage scaledToSize:newSize];
    NSData * destData = UIImageJPEGRepresentation(destImage, 1.0);
    [destData writeToFile:destination atomically:YES];
}


#pragma mark - blurring

// from http://damir.me/ios7-blurring-techniques
+(UIImage *)blurredSnapshotForWindow: (UIWindow *) window
{
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(window.bounds.size, NO, window.screen.scale);
    
    // There he is! The new API method
    [window drawViewHierarchyInRect:window.frame afterScreenUpdates:NO];
    
    // Get the snapshot
    UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    
    // Now apply the blur effect using Apple's UIImageEffect category
    UIImage *blurredSnapshotImage = [snapshotImage applyLightEffect];
    
    
    // Be nice and clean your mess up
    UIGraphicsEndImageContext();
    
    
    // return blurredSnapshotImage;
    return [EUCImageUtilities scaleAndRotateImage:blurredSnapshotImage];
}

// from http://stackoverflow.com/a/3526833/772526
+ (UIImage *)scaleAndRotateImage:(UIImage *)image {
    int kMaxResolution = 2048; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = roundf(bounds.size.width / ratio);
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = roundf(bounds.size.height * ratio);
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    
    boundHeight = bounds.size.height;
    bounds.size.height = bounds.size.width;
    bounds.size.width = boundHeight;
    transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width/2.0);
    
    transform = CGAffineTransformRotate(transform, M_PI / 2.0);
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIImageOrientation orient = image.imageOrientation;
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -264-height); // don't know why but it's off by 264 pixels. Found this by trial and error
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    UIInterfaceOrientation sbOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (sbOrientation == UIInterfaceOrientationLandscapeLeft) {
        return [EUCImageUtilities rotateUIImage:imageCopy];
    }
    return imageCopy;
}

// from http://stackoverflow.com/a/20004215/772526
+ (UIImage*)rotateUIImage:(UIImage*)sourceImage
{
    CGSize size = sourceImage.size;
    UIGraphicsBeginImageContext(size);
    [[UIImage imageWithCGImage:[sourceImage CGImage] scale:1.0 orientation:UIImageOrientationDown] drawInRect:CGRectMake(0,0,size.width ,size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


@end
