//
//  EUCFileSystem.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EUCFileSystem : NSObject

+(uint64_t)getFreeDiskspace;



+(NSString *) documentDir;
+(NSString *) imageDir;
+(NSString *) fileNameForImageWithId: (NSInteger) imageId;
+(NSString *) fileNameForDeploymentPictureWithId: (NSInteger) imageId ;
+(void) makeImageDirIfNecessary;

@end
