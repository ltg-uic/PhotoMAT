//
//  EUCFileSystem.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCFileSystem.h"

@implementation EUCFileSystem


// Taken from http://stackoverflow.com/a/8036586/772526
+(uint64_t)getFreeDiskspace {
    uint64_t totalSpace = 0;
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        NSLog(@"Memory Capacity of %llu MiB with %llu MiB Free memory available.", ((totalSpace/1024ll)/1024ll), ((totalFreeSpace/1024ll)/1024ll));
    } else {
        NSLog(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    
    return totalFreeSpace;
}


+(NSString *) documentDir {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

+(NSString *) imageDir {
    return [[EUCFileSystem documentDir] stringByAppendingPathComponent:@"images"];
}

+(NSString *) fileNameForImageWithId: (NSInteger) imageId {
    return [[EUCFileSystem imageDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"i%ld.jpg", (long) imageId]];
}

+(NSString *) fileNameForDeploymentPictureWithId: (NSInteger) imageId {
    return [[EUCFileSystem imageDir] stringByAppendingPathComponent:[NSString stringWithFormat:@"d%ld.jpg", (long) imageId]];
}

+(void) makeImageDirIfNecessary {
    NSString * imageDir = [EUCFileSystem imageDir];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fileManager fileExistsAtPath:imageDir isDirectory:&isDir]) {
        // do nothing
    }
    else {
        [fileManager createDirectoryAtPath:imageDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
}

+(BOOL)fileExists:(NSString *)fileName {
    NSFileManager * fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:fileName];
}

@end
