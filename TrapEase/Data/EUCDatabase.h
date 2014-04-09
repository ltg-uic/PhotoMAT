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


+(EUCDatabase *) sharedInstance;

-(void) refreshDeployments: (NSArray *) deployments;

-(NSArray *) getDeployments;

-(void) refreshSchools: (NSArray *) schools;

-(NSArray *) schools;

-(BOOL) hasSchools;

-(NSDictionary *) getDeploymentRecord: (NSNumber *) deploymentId;

@end
