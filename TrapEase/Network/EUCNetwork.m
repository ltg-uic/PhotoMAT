//
//  EUCNetwork.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCNetwork.h"
#import "EUCDatabase.h"

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


+(void) getDeploymentDetail: (NSInteger) deploymentId success: (EUCGetSuccessBlock) successBlock failure: (EUCGetFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    [network.sessionManager GET:[NSString stringWithFormat:@"/deployment/%ld", (long) deploymentId]
                     parameters:nil
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSDictionary * result = (NSDictionary *) responseObject;
                            successBlock(result[@"deployment"]);
                        }
                        failure:^(NSURLSessionDataTask *task, NSError *error) {
                            failureBlock([NSString stringWithFormat:@"Error: %@", error]);
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

+(void) createIDs: (NSInteger) numIds forResource: resource successBlock: (EUCNetworkPOSTSuccessBlock) successBlock failureBlock: (EUCNetworkPOSTFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    
    [network.sessionManager POST:[NSString stringWithFormat:@"/%@/%ld", resource, (long)numIds]
                      parameters:nil
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             NSDictionary * result = (NSDictionary *) responseObject;
                             NSArray * newIds = result[@"ids"];
                             for (NSNumber * number in newIds) {
                                 NSInteger newId = [number integerValue];
                                 successBlock(task, newId);
                             }
                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                             failureBlock(task, error);
                         }];
    
}

#pragma mark - PUT
+(void) putResource: (NSString *) resource withId: (NSInteger) resourceId params: (NSDictionary *) params successBlock: (EUCNetworkPUTSuccessBlock) successBlock failureBlock: (EUCNetworkPUTFailureBlock) failureBlock {
   
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    
    [network.sessionManager PUT:[NSString stringWithFormat:@"/%@/%ld", resource, (long)resourceId]
                     parameters:params
                        success:successBlock
                        failure:failureBlock];
    
}

#pragma mark - upload image


+(void) uploadImageData: (NSData *) data forResource: (NSString *) resource withId: (NSInteger) resourceId {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer]
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:[NSString stringWithFormat:@"%@/file/%@/%ld", baseUrl, resource, (long)resourceId]
                                    parameters:nil
                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                        [formData appendPartWithFileData:data
                                                                    name:@"file"
                                                                fileName:@"filename.jpg"
                                                                mimeType:@"image/jpeg"];
                                    }
                                    error:nil];
    
    NSProgress *progress = nil;
    NSDictionary * settings = [[EUCDatabase sharedInstance] settings];
    NSNumber * personId = settings[@"personId"];
    [request setValue:[NSString stringWithFormat:@"WouldntItBeCool%d", [personId intValue]] forHTTPHeaderField:@"X-Trap-Token"];
    
    NSURLSessionUploadTask *uploadTask = [network.sessionManager uploadTaskWithStreamedRequest:request
                                                                                      progress:&progress
                                                                             completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                                 NSLog(@"Resource: %@, resourceId; %ld", resource, (long)resourceId);
                                                                                 if (error) {
                                                                                     NSLog(@"Error: %@", error);
                                                                                 } else {
                                                                                     NSLog(@"%@ %@", response, responseObject);
                                                                                 }
                                                                                 
                                                                                 [[EUCDatabase sharedInstance] onePendingDoneWithType:resource andId:resourceId];

                                                                             }];
    
    [uploadTask resume];
}

#pragma mark - backpacks

+(void)uploadImageData:(NSData *)data toRepo:(NSString *)repoURL completion:(EUCImageRepoPostBlock)completion {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer]
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:repoURL
                                    parameters:nil
                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                        [formData appendPartWithFileData:data
                                                                    name:@"file"
                                                                fileName:@"filename.jpg"
                                                                mimeType:@"image/jpeg"];
                                    }
                                    error:nil];
    
    NSProgress *progress = nil;

    
    NSURLSessionUploadTask *uploadTask = [network.sessionManager uploadTaskWithStreamedRequest:request
                                                                                      progress:&progress
                                                                             completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {

                                                                                 if (error) {
                                                                                     NSLog(@"Error: %@", error);
                                                                                 } else {
                                                                                     NSDictionary * obj = (NSDictionary *) responseObject;
                                                                                     completion(obj[@"url"], obj[@"code"]);
                                                                                 }
                                                                                 

                                                                                 
                                                                             }];
    
    [uploadTask resume];
}


+(void) getBackpack: (NSString *) backpackURL withSelector: (NSDictionary *) selector withSuccessBlock: (EUCGetSuccessBlock) successBlock failureBlock: (EUCGetFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    [network.sessionManager GET:backpackURL
                     parameters:selector
                        success:^(NSURLSessionDataTask *task, id responseObject) {
                            NSArray * result = (NSArray *) responseObject;
                            successBlock(result);
                        }
                        failure:^(NSURLSessionDataTask *task, NSError *error) {
                            failureBlock([NSString stringWithFormat:@"Error: %@", error]);
                        }];
    
}


+(void)putBackpack:(NSDictionary *)backpack toUrl:(NSString *)putURL successBlock: (EUCNetworkPUTSuccessBlock) successBlock failureBlock: (EUCNetworkPUTFailureBlock) failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];
    
    
    [network.sessionManager PUT:putURL
                     parameters:backpack
                        success:successBlock
                        failure:failureBlock];
    
}

+(void)postBackpack:(NSDictionary *)backpack toUrl:(NSString *)postURL successBlock:(EUCNetworkSuccessBlock)successBlock failureBlock:(EUCNetworkFailureBlock)failureBlock {
    EUCNetwork * network = [EUCNetwork sharedNetwork];

    [network.sessionManager POST:postURL
                      parameters:backpack
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             successBlock(nil, responseObject);
                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                             failureBlock(nil, error);
                         }];
}

@end
