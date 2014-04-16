//
//  EUCDatabase.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class EUCLabel;

@interface EUCDatabase : NSObject

@property (readonly, nonatomic) FMDatabase * db;
@property (strong, nonatomic) NSDictionary *settings;
@property (readonly, nonatomic) NSString * schoolName;
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

#pragma mark - local

-(NSInteger) getMinIdForTable: (NSString *) table;

-(void) saveLocalDeploymentWithId: (NSInteger) deploymentId
                        person_id: (NSInteger) personId
                  deployment_date: (NSString *) deployment_date
                         cameraId: (NSInteger) cameraId
                  nominalMarkTime: (NSString *) nominalMarkTime
                   actualMarkTime: (NSString *) actualMarkTime
               camera_trap_number: (NSInteger) trapNumber
                       short_name: (NSString *) shortName
                            notes: (NSString *) notes;


-(void) saveLocalDeploymentPictureWithId: (NSInteger) deploymentPictureId
                                   owner: (NSInteger) personId
                           deployment_id: (NSInteger) deploymentId
                                fileName: (NSString *) fileName;

-(void) saveLocalBurstWithId: (NSInteger) burstId
                       owner: (NSInteger) personId
               deployment_id: (NSInteger) deploymentId
                   burstDate: (NSString *) burstDate;


-(void) saveLocalBurstImageWithId: (NSInteger) imageId
                            owner: (NSInteger) personId
                        imageDate: (NSString *) imageDate
                          burstId: (NSInteger) burstId
                         fileName: (NSString *) fileName
                            width: (NSInteger) width
                           height: (NSInteger) height;

-(NSMutableArray *) getDeploymentImagesForDeploymentWithId: (NSInteger) deploymentId;

-(NSMutableArray *) getBurstForDeploymentWithId: (NSInteger) deploymentId withParser: (NSDateFormatter *) parser;


-(void) fixImages;

#pragma mark - labels

-(NSInteger) addLabel: (NSString *) labelName toBurst: (NSInteger) burstId atLocation: (CGPoint) labelLocation;  // returns label ID
-(void) deleteLabel: (NSInteger) labelId;
-(void) updateLabel: (EUCLabel *) label;

-(NSMutableArray *) labelsForDeployment: (NSInteger) deploymentId;

//
//-(NSArray *) labelsForBurst: (NSInteger) burstId; // returns an array of EUCLabel objects
//-(NSArray *) labelsForBurst: (NSInteger) burstId named: (NSString *) labelName;
//-(NSArray *) labelsForDeployment: (NSInteger) deploymentId;
//
//-(void) deleteAllLabelsNamed:(NSString *) labelName onBurst:(NSInteger) burstId;
//-(void) deleteAllLabelsNamed:(NSString *) labelName;
//
//-(void) renameLabelsNamed: (NSString *) oldLabelName toName: (NSString *) newLabelName forBurst: (NSInteger) burstId;
//-(void) renameLabelsNamed: (NSString *) oldLabelName toName: (NSString *) newLabelName forDeployment: (NSInteger) deploymentId;

@end




















