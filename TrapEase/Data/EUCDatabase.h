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
-(NSMutableArray *) getBurstsForDeploymentsWithIds: (NSSet *) setOfIDs;


#pragma mark - labels

/**
 *  Adds a master label to a deployment
 *
 *  @param labelName    the name of the master label
 *  @param deploymentId the deploymentId
 *
 *  @return an the id of the newly-created master label
 */
-(NSInteger) addMasterLabel: (NSString *) labelName toDeployment: (NSInteger) deploymentId;

/**
 *  Returns an NSMutableArray of all masterLabels associated with a deployment
 *
 *  @param deploymentId the deploymentId
 *
 *  @return an NSMutableArray of masterLabels
 */
-(NSMutableArray *) masterLabelsForDeployment: (NSInteger) deploymentId;

/**
 *  Removes the master label specified by the passed-in id
 *
 *  @param masterLabelId the id of the master label
 */
-(void) removeMasterLabel: (NSInteger) masterLabelId;

/**
 *  Renames the master label specified by the passed-in id
 *
 *  @param masterLabelId the id of the master label
 *  @param newName       the new name of the master label
 */
-(void) renameMasterLabel: (NSInteger) masterLabelId toName: (NSString *) newName;

/**
 *  Add a label to a burst
 *
 *  @param masterLabelId the id of the corresponding master label
 *  @param burstId       the id of the burst to which the label should be added
 *  @param labelLocation a CGPoint representing the x and y location of the label
 *
 *  @return the id of the newly-created label
 */
-(NSInteger) addLabel: (NSInteger) masterLabelId toBurst: (NSInteger) burstId atLocation: (CGPoint) labelLocation;  // returns label ID

/**
 *  Delete the label specified by the passed-in ID
 *
 *  @param labelId the label ID
 */
-(void) deleteLabel: (NSInteger) labelId;

/**
 *  Updates the label identified by the id of the passed in EUCLabel. The x and y location are set based on what the EUCLabel contains
 *
 *  @param label the EUCLabel that contains the id of the label as well as the new x and y locations
 */
-(void) updateLabel: (EUCLabel *) label;

/**
 *  Updates the label identified by the id. The x and y are set based on the passed-in location
 *
 *  @param labelId  the id of the label
 *  @param location the location that needs to be set
 */
-(void) updateLabelWithId:(NSInteger) labelId toLocation: (CGPoint) location;

/**
 *  Returns a list of all labels associated with a burst
 *
 *  @param burstId the burst id
 *
 *  @return An NSMutableArray of labels for that burst
 */
-(NSMutableArray *) labelsForBurst: (NSInteger) burstId;


#pragma mark - Labels - notes


/**
 *  Gets a note associated to a burst
 *
 *  @param burstId the id of the burst we are trying to add a note to
 *  @return the note associated with the current burst
 */
-(NSString *) getNoteForBurst: (NSInteger) burstId;

/**
 *  Adds a note to a burst
 *
 *  @param burstId the id of the burst we are trying to add a note to
 *  @param note    the note we need to add
 */
-(void) addNote: (NSString *) note toBurst: (NSInteger) burstId;

/**
 *  Update a note in a burst
 *
 *  @param burstId the id of the burst whose note we are trying to edit
 *  @param note    the note we need to add
 */
-(void) updateNote: (NSString *) note inBurst: (NSInteger) burstId;

/**
 *  Delete a note from a burst
 *
 *  @param burstId the id of the burst we are trying to add a note to
 */
-(void) deleteNoteFromBurst: (NSInteger) burstId;


/**
 *  Returns the visited status of a certain burst
 *
 *  @param burstId the id of the burst
 *  @return the visited status of a burst
 */
-(BOOL) getVisitedForBurst: (NSInteger) burstId;


/**
 *  Update visited in a burst
 *
 *  @param burstId the id of the burst whose visitated state we are trying to change
 *  @param status    the visited  status we are trying to set
 */
-(void) updateVisited: (BOOL) status inBurst: (NSInteger) burstId;


@end




















