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
+(NSString *) tfileNameForImageWithId: (NSInteger) imageId;
+(NSString *) tfileNameForDeploymentPictureWithId: (NSInteger) imageId ;
+(void) makeImageDirIfNecessary;
+(BOOL) fileExists: (NSString *) fileName;
+(void) moveFile: (NSString *) source toFile:(NSString *) dest;
+(NSString *) thumbnailForFile: (NSString *) fileName;
@end
