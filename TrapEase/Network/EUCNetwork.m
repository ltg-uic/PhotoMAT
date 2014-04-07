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

static NSString * baseUrl = @"http://trap.euclidsoftware.com";

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
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
//        [_sessionManager.requestSerializer setValue:sessionToken forHTTPHeaderField:@"token"];

    }
    return self;
}

+(void)updatePersonId:(NSNumber *)personId {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    [network.sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"WouldntItBeCool%d", [personId intValue]] forHTTPHeaderField:@"X-Trap-Token"];
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

+(void) getObject: (NSString *) resourceName WithSuccessBlock: (EUCGetSuccessBlock) successBlock failureBlock: (EUCGetFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    [network.sessionManager GET:[NSString stringWithFormat:@"/%@", resourceName]
                     parameters:nil
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSDictionary * result = (NSDictionary *) responseObject;
                            successBlock(result[resourceName]);
                        }
                        failure:^(NSURLSessionDataTask *task, NSError *error) {
                            failureBlock([NSString stringWithFormat:@"Error: %@", error]);
                        }];
    
}


+(void) getSchoolsWithSuccessBlock:(EUCSchoolSuccessBlock)successBlock failureBlock:(EUCSchoolFailureBlock)failureBlock {
    [EUCNetwork getObject:@"school" WithSuccessBlock:successBlock failureBlock:failureBlock];
}

+(void)getDeploymentsWithVisibility: (NSString *) visibility andSuccessBlock:(EUCDeploymentsSuccessBlock)successBlock failureBlock:(EUCDeploymentsFailureBlock)failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    [network.sessionManager GET:[NSString stringWithFormat:@"/sets.json/%@", visibility]
                     parameters:nil
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSDictionary * result = (NSDictionary *) responseObject;
                            successBlock(result[@"sets"]);
                        }
                        failure:^(NSURLSessionDataTask *task, NSError *error) {
                            NSHTTPURLResponse * response = (NSHTTPURLResponse *) task.response;
                            if (response.statusCode == 409)  {
                                failureBlock([NSString stringWithFormat:@"Please select a group first"]);
                            }
                            else {
                                failureBlock([NSString stringWithFormat:@"Error: %@", error]);
                            }
                        }];
}



#pragma mark - POST

+(void) createIDForResource: (NSString *) resource successBlock: (EUCNetworkPOSTSuccessBlock) successBlock failureBlock: (EUCNetworkPOSTFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];

    
    [network.sessionManager POST:[NSString stringWithFormat:@"/%@", resource]
                      parameters:nil
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             NSDictionary * result = (NSDictionary *) responseObject;
                             NSInteger newId = [result[@"id"] integerValue];
                             successBlock(task, newId);
                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                             failureBlock(task, error);
                         }];
    
}

#pragma mark - PUT 
+(void) putResource: (NSString *) resource withId: (NSInteger) resourceId params: (NSDictionary *) params successBlock: (EUCNetworkPUTSuccessBlock) successBlock failureBlock: (EUCNetworkPUTFailureBlock) failureBlock {
   
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    
    [network.sessionManager PUT:[NSString stringWithFormat:@"/%@/%ld", resource, resourceId]
                     parameters:params
                        success:successBlock
                        failure:failureBlock];
    
}

@end
