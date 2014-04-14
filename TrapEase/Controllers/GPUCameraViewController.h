//
//  GPUCameraViewController.h
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/13/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GPUImageCameraDelegate <NSObject>

-(void) pictureTaken;

@end
@interface GPUCameraViewController : UIViewController
@property (weak, nonatomic) id<GPUImageCameraDelegate> delegate;

@end
