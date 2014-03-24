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

typedef void(^EUCDeploymentsSuccessBlock)(NSArray * deployments);
typedef void(^EUCDeploymentsFailureBlock)(NSString * reason);

typedef void(^EUCDownloadTaskCompletionBlock)(NSURLResponse * response, NSURL * filePath, NSError * error);

@interface EUCNetwork : NSObject

+(void) downloadImage:(NSString *) imageURL toFile: (NSString *) filePath completion: (EUCDownloadTaskCompletionBlock) completionBlock;


+(void) getDeploymentsWithSuccessBlock: (EUCDeploymentsSuccessBlock) successBlock failureBlock: (EUCDeploymentsFailureBlock) failureBlock;

@end
