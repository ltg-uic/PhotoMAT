//
//  EUCDatabase.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

@interface EUCDatabase : NSObject

@property (readonly, nonatomic) FMDatabase * db;
@property (strong, nonatomic) NSDictionary *settings;
@property (readonly, nonatomic) NSString * className;
@property (readonly, nonatomic) NSString * groupName;

+(EUCDatabase *) sharedInstance;

-(void) refreshDeployments: (NSArray *) deployments;

-(NSArray *) getDeployments;

-(void) refreshSchools: (NSArray *) schools;

-(NSArray *) schools;

-(BOOL) hasSchools;

-(NSDictionary *) getDeploymentRecord: (NSNumber *) deploymentId;

-(void) writePendingUploadOf: (NSString *) fileName withType: (NSString *) fileType andId: (NSInteger) imageId;

-(void) consumePendingQueue;

-(void) onePendingDoneWithType:(NSString *)fileType andId:(NSInteger)imageId;



@end
