//
//  EUCNetwork.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef void(^EUCBlock)(void);

typedef void(^EUCNetworkSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void(^EUCNetworkFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

typedef void(^EUCGetSuccessBlock)(NSArray * objects);
typedef void(^EUCGetFailureBlock)(NSString * reason);


typedef EUCGetSuccessBlock EUCDeploymentsSuccessBlock;
typedef EUCGetFailureBlock EUCDeploymentsFailureBlock;
typedef EUCGetSuccessBlock EUCSchoolSuccessBlock;
typedef EUCGetFailureBlock EUCSchoolFailureBlock;


typedef void(^EUCDownloadTaskCompletionBlock)(NSURLResponse * response, NSURL * filePath, NSError * error);

@interface EUCNetwork : NSObject

+(void) downloadImage:(NSString *) imageURL toFile: (NSString *) filePath completion: (EUCDownloadTaskCompletionBlock) completionBlock;

+(void) getObject: (NSString *) object WithSuccessBlock: (EUCGetSuccessBlock) successBlock failureBlock: (EUCGetFailureBlock) failureBlock;

+(void) getDeploymentsWithSuccessBlock: (EUCDeploymentsSuccessBlock) successBlock failureBlock: (EUCDeploymentsFailureBlock) failureBlock;
+(void) getSchoolsWithSuccessBlock: (EUCSchoolSuccessBlock) successBlock failureBlock: (EUCSchoolFailureBlock) failureBlock;

@end
