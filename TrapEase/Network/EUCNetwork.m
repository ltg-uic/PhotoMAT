//
//  EUCNetwork.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCNetwork.h"

#define BASEURL "http://trap.euclidsoftware.com"

@interface EUCNetwork ()
{}

@property (strong, nonatomic) AFHTTPSessionManager *sessionManager;

@end


@implementation EUCNetwork

+ (instancetype)sharedNetwork {
    static EUCNetwork *_sharedNetwork = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedNetwork = [[EUCNetwork alloc] init];
    });
    
    return _sharedNetwork;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://trap.euclidsoftware.com"]];
//        [_sessionManager.requestSerializer setValue:sessionToken forHTTPHeaderField:@"token"];

    }
    return self;
}


+(void)downloadImage:(NSString *)imageURL toFile:(NSString *)filePath completion:(EUCDownloadTaskCompletionBlock)completionBlock {
    NSFileManager * fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        completionBlock(nil, [NSURL fileURLWithPath: filePath], nil);
        return;
    }
    
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    NSURL *URL = [network.sessionManager.baseURL URLByAppendingPathComponent:imageURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
//    NSString * sessionToken = [EUCKeyChain get:@"sessionToken"];
//    if (sessionToken) {
//        [request setValue:sessionToken forHTTPHeaderField:@"token"];
//    }
    
    
    NSURLSessionDownloadTask *downloadTask =
    [network.sessionManager downloadTaskWithRequest:request
                                           progress:nil
                                        destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                            NSURL * url =  [NSURL fileURLWithPath:filePath];
                                            return  url;
                                        }
                                  completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                      NSLog(@"File downloaded to: %@", filePath);
                                      completionBlock(response, filePath, error);
                                  }];
    [downloadTask resume];
    
}

+(void) getObject: (NSString *) object WithSuccessBlock: (EUCGetSuccessBlock) successBlock failureBlock: (EUCGetFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    [network.sessionManager GET:[NSString stringWithFormat:@"/%@", object]
                     parameters:nil
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSDictionary * result = (NSDictionary *) responseObject;
                            successBlock(result[object]);
                        }
                        failure:^(NSURLSessionDataTask *task, NSError *error) {
                            failureBlock([NSString stringWithFormat:@"Error: %@", error]);
                        }];
    
}


+(void) getSchoolsWithSuccessBlock:(EUCSchoolSuccessBlock)successBlock failureBlock:(EUCSchoolFailureBlock)failureBlock {
    [EUCNetwork getObject:@"school" WithSuccessBlock:successBlock failureBlock:failureBlock];
}

+(void)getDeploymentsWithSuccessBlock:(EUCDeploymentsSuccessBlock)successBlock failureBlock:(EUCDeploymentsFailureBlock)failureBlock {
    [EUCNetwork getObject:@"deployment" WithSuccessBlock:successBlock failureBlock:failureBlock];
}



@end
