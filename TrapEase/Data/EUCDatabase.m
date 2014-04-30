//
//  EUCDatabase.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/23/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//
#import "EUCDatabase.h"
#import "DDLog.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "EUCNetwork.h"
#import "EUCImage.h"
#import "EUCBurst.h"
#import "EUCFileSystem.h"
#import "EUCLabel.h"
#import "EUCMasterLabel.h"

static EUCDatabase * database;
static const int ddLogLevel = LOG_LEVEL_INFO;

#define kDBFileName @"trap.db"
#define kDBBaseName @"trap"

@interface EUCDatabase () {
    NSDictionary * _settings;
}
@property (strong, nonatomic) FMDatabase * db;
@property (strong, nonatomic) dispatch_queue_t pendingQueue;
@property (assign, nonatomic) BOOL queueBeingConsumed;
@property (strong, nonatomic) FMDatabaseQueue *dbq;


@end

@implementation EUCDatabase

+(EUCDatabase *) sharedInstance {
    if (database == nil) {
        database = [[EUCDatabase alloc] init];
        [database openDatabase];
        [database consumePendingQueue];
    }
    return database;
}

-(EUCDatabase *) init {
    if (self = [super init]) {
        _pendingQueue = dispatch_queue_create("com.euclidsoftware.pendingQueue", NULL);
    }
    return self;
}

-(void) closeDatabase {
    [self.db close];
}

-(void) openDatabase {
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString * documentsDirectory = [paths objectAtIndex:0];
	NSString * databasePath = [documentsDirectory stringByAppendingPathComponent:kDBFileName];
    DDLogInfo(@"Database path is %@", databasePath);
	
	NSFileManager *filemgr = [NSFileManager defaultManager];
    
    NSString * originalDb = [[NSBundle mainBundle] pathForResource:kDBBaseName ofType:@"db"];
    
    // copy database if necessary
    if ([filemgr fileExistsAtPath:databasePath] == NO) {
        // copy database file
        
		if ([filemgr copyItemAtPath: originalDb toPath: databasePath error: NULL]  == YES) {
			// do nothing
		}
		else {
            DDLogError(@"Failed to copy  database to Documents directory: %@", databasePath);
            //            [Flurry logEvent:@"ERROR" withParameters:@{ @"Type": @"Failed to copy prefs database to Documents directory"}];
		}
        
	}
    
    self.db = [FMDatabase databaseWithPath:databasePath];
    if (![self.db open]) {
        //        [Flurry logEvent:@"ERROR" withParameters:@{ @"Type": @"Failed to open originalDb"}];
        DDLogError(@"Failed to open database file");
    }
    
    // check to see if database needs to be updated
    double currentVersion = 1.0;
    
    NSString * sql = @"SELECT versionNumber from databaseVersion";
    FMResultSet * rs = [self.db executeQuery:sql];
    double foundVersion = 0.0;
    while ([rs next]) {
        foundVersion = [rs doubleForColumnIndex:0];
    }
    [rs close];
    
    if (foundVersion < currentVersion) {
        [self closeDatabase];
        
        [filemgr removeItemAtPath:databasePath error:nil];
        
		if ([filemgr copyItemAtPath: originalDb toPath: databasePath error: NULL]  == YES) {
			// do nothing
		}
		else {
            DDLogError(@"Failed 2 to copy prefs database to Documents directory: %@", databasePath);
            //            [Flurry logEvent:@"ERROR" withParameters:@{ @"Type": @"Failed to copy prefs database to Documents directory"}];
		}
        self.db = [FMDatabase databaseWithPath:databasePath];
        if (![self.db open]) {
            //        [Flurry logEvent:@"ERROR" withParameters:@{ @"Type": @"Failed to open originalDb"}];
            DDLogError(@"Failed 2 to open database file");
        }
    }
    
    //self.dbq = [FMDatabaseQueue databaseQueueWithPath:aPath];
    
    // create the label table if it's not already there
    [self createLabelTableIfNecessary];
    [self fixImageFilenames];
}

-(void) fixImageFilenames {
    NSString * sql = @"SELECT id from image order by id";
    FMResultSet * rs = [self.db executeQuery:sql];
    NSString * updateSql = @"UPDATE image set file_name=? where id=?";
    while ([rs next]) {
        NSInteger imageId = [rs intForColumnIndex:0];
        NSString * fixedFileName = [EUCFileSystem fileNameForImageWithId:imageId];
        [self.db executeUpdate:updateSql, fixedFileName, @(imageId)];
    }
    [rs close];
    
    sql = @"SELECT id from deployment_picture order by id";
    rs = [self.db executeQuery:sql];
    updateSql = @"UPDATE deployment_picture set file_name=? where id=?";
    while ([rs next]) {
        NSInteger imageId = [rs intForColumnIndex:0];
        NSString * fixedFileName = [EUCFileSystem fileNameForDeploymentPictureWithId:imageId];
        [self.db executeUpdate:updateSql, fixedFileName, @(imageId)];
    }
    [rs close];

}

-(void) createLabelTableIfNecessary {
    NSString * sql = @"pragma table_info(master_label)";
    FMResultSet * rs = [self.db executeQuery:sql];
    if ([rs next]) {
        [rs close];
        // it's already there
        NSLog(@"Table master_label already exists");
        return;
    }
    
    [self.db executeUpdate:@"drop table label"];
    [self.db executeUpdate:@"drop table master_label"];

    sql = @"CREATE TABLE master_label ("
    "id SERIAL UNIQUE PRIMARY KEY NOT NULL"
    ", name VARCHAR(256) NOT NULL"
    ", deployment_id INT NOT NULL REFERENCES deployment (id) ON DELETE CASCADE ON UPDATE CASCADE"
    ")";
    [self.db executeUpdate:sql];
    

    sql = @"CREATE TABLE label ("
    "      id SERIAL UNIQUE PRIMARY KEY NOT NULL"
    "    , owner INT NOT NULL REFERENCES person(id) ON UPDATE CASCADE"
    "    , burst_id INT NOT NULL REFERENCES burst(id) ON DELETE CASCADE ON UPDATE CASCADE"
    "    , x INT NOT NULL "
    "    , y INT NOT NULL"
    "    , master_label_id INT NOT NULL REFERENCES master_label (id) ON DELETE CASCADE ON UPDATE CASCADE"
    ")";
    [self.db executeUpdate:sql];
    
    [self.db executeUpdate:@"create index i_label_id on label(id)"];
    [self.db executeUpdate:@"CREATE index i_label_bid on label(burst_id)"];
    
    NSLog(@"created table label");

}

#pragma mark - settings
-(NSDictionary *)settings {
    if (_settings) {
        return _settings;
    }
    
    NSString * sql = @"select schoolId, classId, personId, visibility from settings";
    FMResultSet * rs = [self.db executeQuery:sql];
    if ([rs next]) {
        _settings = @{@"schoolId": @([rs intForColumnIndex:0]),
                      @"classId": @([rs intForColumnIndex:1]),
                      @"personId": @([rs intForColumnIndex:2]),
                      @"visibility": [rs stringForColumnIndex:3]
                      };
    }

    [rs close];
    
    return _settings;
}

-(void)setSettings:(NSDictionary *)settings {
    NSString * sql = @"update settings set schoolId=?, classId=?, personId=?, visibility=?";
    
    [self.db executeUpdate:sql, settings[@"schoolId"], settings[@"classId"], settings[@"personId"], settings[@"visibility"]];
    
    _settings = [NSDictionary dictionaryWithDictionary:settings]; // make a copy of the settings, and leave the original one untouched
    
}

-(NSString *)schoolName {
    NSDictionary * settings = self.settings;
    NSString * sql = @"Select name from school where id=?";
    FMResultSet * rs = [self.db executeQuery:sql, settings[@"schoolId"]];
    if ([rs next]) {
        NSString * result = [rs stringForColumnIndex:0];
        [rs close];
        return result;
    }
    [rs close];
    return nil;
}

-(NSString *)className {
    NSDictionary * settings = self.settings;
    NSString * sql = @"Select name from class where id=?";
    FMResultSet * rs = [self.db executeQuery:sql, settings[@"classId"]];
    if ([rs next]) {
        NSString * result = [rs stringForColumnIndex:0];
        [rs close];
        return result;
    }
    [rs close];
    return nil;
}


-(NSString *)groupName {
    NSDictionary * settings = self.settings;
    NSString * sql = @"Select first_name from person where id=?";
    FMResultSet * rs = [self.db executeQuery:sql, settings[@"personId"]];
    if ([rs next]) {
        NSString * result = [rs stringForColumnIndex:0];
        [rs close];
        return result;
    }
    [rs close];
    return nil;
}



#pragma mark - schools

-(BOOL)hasSchools {
    NSString * sql = @"select id from school";
    FMResultSet * rs = [self.db executeQuery:sql];
    if ([rs next]) {
        [rs close];
        return YES;
    }
    [rs close];
    return NO;
}

-(void) refreshSchools: (NSArray *) schools {
    [self clearTable:@"person"];
    [self clearTable:@"class"];
    [self clearTable:@"school"];
    
    
    for (NSDictionary * school in schools) {
        [self saveSchool: school];
    }
}

-(void) saveSchool: (NSDictionary *) school {
    [self.db executeUpdate:@"insert into school (id, name) values (?, ?)", school[@"id"], school[@"name"]];
    
    if (school[@"class"] != [NSNull null]) {
        for (NSDictionary * classRoom in school[@"class"]) {
            [self saveClass: classRoom] ;
        }
    }
}

-(void) saveClass: (NSDictionary *) classRoom {
    [self.db executeUpdate:@"insert into class (id, name, school_id) values (?, ?, ?)", classRoom[@"id"], classRoom[@"name"], classRoom[@"school_id"]];
    
    if (classRoom[@"person"] != [NSNull null]) {
        for (NSDictionary * person in classRoom[@"person"]) {
            [self savePerson: person forClass: classRoom[@"id"]];
        }
    }
}

-(void) savePerson: (NSDictionary *) person forClass: (NSNumber *) classId {
    [self.db executeUpdate:@"insert or replace into person (id, first_name, last_name, class_id) values (?, ?, ?, ?)", person[@"id"], person[@"first_name"], person[@"last_name"], person[@"class_id"]];
}

-(NSArray *) schools {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:8];
    NSString * sql = @"select id, name from school order by id";
    FMResultSet * rs = [self.db executeQuery:sql];
    while ([rs next]) {
        NSInteger schoolId = [rs intForColumnIndex:0];
        
        NSMutableDictionary * row = [NSMutableDictionary dictionaryWithCapacity:3];
        row[@"id"] = @(schoolId);
        row[@"name"] = [rs stringForColumnIndex:1];
        row[@"class"] = [self classRoomsForSchool: schoolId];
        
        [array addObject:row];
    }
    [rs close];
    return array;
}

-(NSArray *) classRoomsForSchool: (NSInteger) schoolId {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:8];
//    NSString * sql = @"select id, name from class where school_id = ? and name != 'test' order by name";
    NSString * sql = @"select id, name from class where school_id = ?  order by name";
    FMResultSet * rs = [self.db executeQuery:sql, @(schoolId)];
    while ([rs next]) {
        NSInteger classId = [rs intForColumnIndex:0];
        
        NSMutableDictionary * row = [NSMutableDictionary dictionaryWithCapacity:3];
        row[@"id"] = @(classId);
        row[@"name"] = [rs stringForColumnIndex:1];
        row[@"person"] = [self personsForClass: classId];
        
        [array addObject:row];
    }
    [rs close];
    return array;
}

-(NSArray *) personsForClass: (NSInteger) classId {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:32];
    NSString * sql = @"select p.id, p.first_name, p.last_name from person p  where p.class_id = ? order by p.first_name";
    FMResultSet * rs = [self.db executeQuery:sql, @(classId)];
    while ([rs next]) {
        NSInteger personId = [rs intForColumnIndex:0];
        
        NSMutableDictionary * row = [NSMutableDictionary dictionaryWithCapacity:3];
        row[@"id"] = @(personId);
        row[@"firstName"] = [rs stringForColumnIndex:1];
        row[@"lastName"] = [rs stringForColumnIndex:2];
        
        [array addObject:row];
    }
    [rs close];
    return array;
}

#pragma mark - deployments

-(NSArray *) getDeployments {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:64];
    NSDateFormatter * formatter1 = [[NSDateFormatter alloc] init];
    [formatter1 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z"];
    [formatter1 setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd hh:mm a"];
    
    NSString * sql = @"select person_name, deployment_date, school_name, class_name, short_name, id, person_id from deployment order by deployment_date desc";
    
    FMResultSet * rs = [self.db executeQuery:sql];
    
    while ([rs next]) {
        
        NSString * dateStr = [rs stringForColumnIndex:1];
        NSDate * dateDate = [formatter1 dateFromString:dateStr];
        NSString * fixedDateStr = [formatter stringFromDate:dateDate];
        NSDictionary * row = @{@"person_name": [rs stringForColumnIndex:0],
                               @"date": fixedDateStr,
                               @"school_name": [rs stringForColumnIndex:2],
                               @"class_name": [rs stringForColumnIndex:3],
                               @"short_name": [rs stringForColumnIndex:4],
                               @"id": @([rs intForColumnIndex:5]),
                               @"person_id": @([rs intForColumnIndex:6])

                               };
        
        [array addObject:row];
    }
    [rs close];
    
    return [NSArray arrayWithArray:array];
    
}

-(void) refreshDeployments: (NSArray *) deployments {
    
//    [self clearTable: @"tag"];
//    [self clearTable:@"image"];
//    [self clearTable:@"burst"];
//    [self clearTable:@"deployment_picture"];
    [self clearTable:@"deployment"];
    
    if (![deployments isEqual: [NSNull null]]) {
        for (NSDictionary * deployment in deployments) {
            [self saveDeployment: deployment];
        }
    }
}

-(void) saveDeployment: (NSDictionary *) deployment {
    NSMutableArray * cols = [NSMutableArray arrayWithCapacity:16];
    NSMutableArray * vals = [NSMutableArray arrayWithCapacity:16];
    
    
    [self addColumn: @"id" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"deployment_date" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"latitude" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"longitude" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"notes" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"short_name" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"camera_height_cm" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"camera_azimuth_rad" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"camera_elevation_rad" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"camera" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"nominal_mark_time" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"actual_mark_time" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"person_name" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"class_name" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"school_name" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"camera_trap_number" fromDictionary:deployment toColumns:cols andValues:vals];
    [self addColumn: @"person_id" fromDictionary:deployment toColumns:cols andValues:vals];
    
    [self insertColumns:cols andValues:vals intoTable:@"deployment"];
}


-(void) clearTable: (NSString *) tableName {
    [self.db executeUpdate:[NSString stringWithFormat:@"delete from %@", tableName]];
}


-(NSDictionary *) getDeploymentRecord:(NSNumber *)deploymentId {
    NSString * sql = @"select deployment_date, notes, short_name, strftime('%Y-%m-%dT%H:%M:%S.000Z', actual_mark_time), camera_trap_number from deployment where id=?";
    
    FMResultSet * rs = [self.db executeQuery:sql, deploymentId];
    
    if ([rs next]) {
        NSString * deployment_date = [rs stringForColumnIndex:0];
        NSString * notes = [rs stringForColumnIndex:1];
        NSString * short_name = [rs stringForColumnIndex:2];
        NSString * actual_mark_time = [rs stringForColumnIndex:3];
        NSNumber * camera_trap_number = @([rs intForColumnIndex:4]);
        if (notes == nil) { notes = @""; }
        

        NSDictionary * row = @{@"deployment_date": deployment_date,
                               @"notes": notes,
                               @"short_name": short_name,
                               @"actual_mark_time": actual_mark_time,
                               @"camera_trap_number": camera_trap_number
                               };
        
        [rs close];
        return row;
    }
    
    return nil;
}


#pragma mark - writing helper functions

-(NSString *) placeHoldersForColumns: (NSArray *) cols {
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:[cols count]];
    for (int i = 0; i < [cols count] ; i++) {
        [array addObject:@"?"];
    }
    return [array componentsJoinedByString:@", "];
}

-(void) addColumn: (NSString *) columnName
    fromDictionary:(NSDictionary *) dict
         toColumns: (NSMutableArray *) columns
         andValues: (NSMutableArray *) values {
    [self addValueOf:columnName asColumn:columnName fromDictionary:dict toColumns:columns andValues:values];
}

-(void) addValueOf: (NSString *) jsonKey
          asColumn: (NSString *) columnName
    fromDictionary:(NSDictionary *) dict
         toColumns: (NSMutableArray *) columns
         andValues: (NSMutableArray *) values {
    
    if (dict && dict[jsonKey]) {
        [columns addObject:columnName];
        [values addObject:dict[jsonKey]];
    }
}

-(void) insertColumns: (NSArray *) cols andValues: (NSArray *) vals intoTable: (NSString *) table {
    BOOL ok = [self.db executeUpdate:[NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
                                      table,
                                      [cols componentsJoinedByString:@", "],
                                      [self placeHoldersForColumns:cols]]
                withArgumentsInArray:vals];
    
    if (!ok) {
        //        [Flurry logEvent:@"ERROR" withParameters:@{ @"Type": @"bookmarkListUpdateFailed"}];
        DDLogError(@"Couldn't insert into table %@: %@", table, [self.db lastErrorMessage]);
    }
    
}

#pragma mark - Pending

-(void)writePendingUploadOf:(NSString *)fileName withType:(NSString *)fileType andId:(NSInteger)imageId {
    NSString * sql = @"insert into pendingPictures (file_name, image_id, resource, status) values (?, ?, ?, ?)";
    [self.db executeUpdate:sql, fileName, @(imageId), fileType, @"new"];
}

-(void)consumePendingQueue {
    
    @synchronized(self) {
        if (self.queueBeingConsumed) {
            DDLogInfo(@"Already being consumed. Not doing anything");
            return;
        }
        
        DDLogInfo(@"Gonna consume queue");
        self.queueBeingConsumed = YES;
    }
    
    NSString * sql = @"select file_name, image_id, resource from pendingPictures where status=?";
    FMResultSet * rs = [self.db executeQuery:sql, @"new"];
    
    if ([rs next]) {
        NSString * fileName = [rs stringForColumnIndex:0];
        NSInteger  imageId = [rs intForColumnIndex:1];
        NSString * resource = [rs stringForColumnIndex:2];
        DDLogInfo(@"CONSUMING: %@ %@", resource, fileName);
        NSData * data = [NSData dataWithContentsOfFile:fileName];
        [EUCNetwork uploadImageData: data forResource:resource withId:imageId];
        [rs close];
    }
    else {
        @synchronized(self) {
            DDLogInfo(@"Nothing to consume");
            self.queueBeingConsumed = NO;
        }
    }

}

-(void) onePendingDoneWithType:(NSString *)fileType andId:(NSInteger)imageId {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            @synchronized(self) {
                self.queueBeingConsumed = NO;
                [self.db executeUpdate:@"update pendingPictures set status=? where status=? and resource=? and image_id=?",
                 @"done", @"new", fileType, @(imageId)];
            }
            [self consumePendingQueue];

        });

}

#pragma mark - localUsage

-(NSInteger)getMinIdForTable:(NSString *)table {
    NSString * sql = [NSString stringWithFormat:@"SELECT MAX(id) from %@", table];
    FMResultSet * rs = [self.db executeQuery:sql];
    int maxId = 0;
    if ([rs next]) {
        maxId = [rs intForColumnIndex:0];
        [rs close];
    }

    return maxId + 1;
}


-(void)saveLocalDeploymentWithId:(NSInteger)deploymentId
                       person_id:(NSInteger)personId
                 deployment_date:(NSString *)deployment_date
                        cameraId:(NSInteger)cameraId
                 nominalMarkTime:(NSString *)nominalMarkTime
                  actualMarkTime:(NSString *)actualMarkTime
              camera_trap_number:(NSInteger)trapNumber
                      short_name:(NSString *)shortName
                           notes:(NSString *)notes {

    NSString * sql = @"INSERT INTO deployment(id, person_id, deployment_date, notes, short_name, camera, nominal_mark_time, actual_mark_time, person_name, class_name, school_name, camera_trap_number) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    [self.db executeUpdate:sql
     , @(deploymentId)
     , @(personId)
     , deployment_date
     , notes
     , shortName
     , @(cameraId)
     , nominalMarkTime
     , actualMarkTime
     , self.groupName
     , self.className
     , self.schoolName
     , @(trapNumber)
     ];
     
}

-(void)saveLocalDeploymentPictureWithId:(NSInteger)deploymentPictureId owner:(NSInteger)personId deployment_id:(NSInteger)deploymentId fileName:(NSString *)fileName {
    NSString * sql = @"INSERT INTO deployment_picture(id, owner, deployment_id, file_name) values(?, ?, ?, ?)";
    [self.db executeUpdate:sql, @(deploymentPictureId), @(personId), @(deploymentId), fileName];
}


-(void)saveLocalBurstWithId:(NSInteger)burstId owner:(NSInteger)personId deployment_id:(NSInteger)deploymentId burstDate:(NSString *)burstDate {
    NSString * sql = @"INSERT INTO burst(id, owner, deployment_id, burst_date) values(?, ?, ?, ?)";
    [self.db executeUpdate:sql, @(burstId), @(personId), @(deploymentId), burstDate];
}

-(void)saveLocalBurstImageWithId:(NSInteger)imageId owner:(NSInteger)personId imageDate:(NSString *)imageDate burstId:(NSInteger)burstId fileName:(NSString *)fileName width:(NSInteger)width height:(NSInteger)height {
    NSString * sql = @"INSERT INTO image(id, owner, image_date, burst_id, file_name, width, height) values(?, ?, ?, ?, ?, ?, ?)";
    [self.db executeUpdate:sql, @(imageId), @(personId), imageDate, @(burstId), fileName, @(width), @(height)];
}

-(NSMutableArray *)getDeploymentImagesForDeploymentWithId:(NSInteger)deploymentId {
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:16];
    
    NSString * sql = @"SELECT id, file_name from deployment_picture where deployment_id=? order by id";
    FMResultSet * rs = [self.db executeQuery: sql, @(deploymentId)];
    while ([rs next]) {
        EUCImage * image = [[EUCImage alloc] init];
        image.filename = [rs stringForColumnIndex:1];
        [result addObject:image];
    }
    [rs close];
    return result;
}

-(NSMutableArray *)getBurstForDeploymentWithId:(NSInteger)deploymentId withParser:(NSDateFormatter *)parser {
    NSMutableArray * bursts = [[NSMutableArray alloc] initWithCapacity:32];
    
    NSString * sql = @"Select id, burst_date from burst where deployment_id=? order by id";
    FMResultSet * rs = [self.db executeQuery:sql, @(deploymentId)];
    
    while ([rs next]) {
        EUCBurst * burst = [[EUCBurst alloc] init];
        burst.burstId = [rs intForColumnIndex:0];
        [bursts addObject:burst];
    }
    [rs close];
    
    sql = @"SELECT id, strftime('%Y-%m-%dT%H:%M:%S.000Z', image_date), file_name, width, height from image where burst_id=? order by id";
    for (EUCBurst * burst in bursts) {
        rs = [self.db executeQuery:sql, @(burst.burstId)];
        burst.images = [NSMutableArray arrayWithCapacity:9];
        while ([rs next]) {
            EUCImage * image = [[EUCImage alloc] init];
            image.filename = [rs stringForColumnIndex:2];
            image.assetDate = [parser dateFromString:[rs stringForColumnIndex:1]];
            image.dimensions = CGSizeMake([rs intForColumnIndex:3], [rs intForColumnIndex:4]);
            [burst.images addObject:image];
        }
        [rs close];
    }
    
    return bursts;
}

-(NSMutableArray *)getBurstsForDeploymentsWithIds:(NSSet *)setOfIDs  {
    NSDateFormatter * parser = [[NSDateFormatter alloc] init];
    [parser setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z"];
    [parser setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

    NSMutableArray * bursts = [[NSMutableArray alloc] initWithCapacity:128];
    NSString * sql;
    sql = @"CREATE TEMPORARY TABLE depIds (depId int)";
    [self.db executeUpdate:sql];
    
    sql = @"insert into depIds (depId) values(?)";
    for (NSNumber * number in setOfIDs) {
        [self.db executeUpdate:sql, number];
    }
    
    sql = @"Select id, burst_date from burst b join depIds i on b.deployment_id = i.depId order by id";
    FMResultSet * rs = [self.db executeQuery:sql];
    
    while ([rs next]) {
        EUCBurst * burst = [[EUCBurst alloc] init];
        burst.burstId = [rs intForColumnIndex:0];
        [bursts addObject:burst];
    }
    [rs close];
    
    sql = @"SELECT id, strftime('%Y-%m-%dT%H:%M:%S.000Z', image_date), file_name, width, height from image where burst_id=? order by id";
    for (EUCBurst * burst in bursts) {
        rs = [self.db executeQuery:sql, @(burst.burstId)];
        burst.images = [NSMutableArray arrayWithCapacity:9];
        while ([rs next]) {
            EUCImage * image = [[EUCImage alloc] init];
            image.filename = [rs stringForColumnIndex:2];
            image.assetDate = [parser dateFromString:[rs stringForColumnIndex:1]];
            image.dimensions = CGSizeMake([rs intForColumnIndex:3], [rs intForColumnIndex:4]);
            [burst.images addObject:image];
        }
        [rs close];
    }
    
    [self.db executeUpdate:@"DROP TABLE depIds"];

    
    return bursts;
}


#pragma mark - labels

/**
 *  Adds a master label to a deployment
 *
 *  @param labelName    the name of the master label
 *  @param deploymentId the deploymentId
 *
 *  @return an the id of the newly-created master label
 */
-(NSInteger)addMasterLabel:(NSString *)labelName toDeployment:(NSInteger)deploymentId {
    NSString * sql ;
    FMResultSet * rs;
    
    sql = @"select max(id) from master_label";
    rs = [self.db executeQuery:sql];
    if ([rs next]) {
        NSInteger masterLabelId = [rs intForColumnIndex:0];
        masterLabelId++;
        [rs close];
        [self.db executeUpdate:@"insert into master_label (id, name, deployment_id) values(?, ?, ?)", @(masterLabelId), labelName, @(deploymentId)];
        return masterLabelId;
    }
    return 0;
}


/**
 *  Returns an NSArray of all masterLabels associated with a deployment
 *
 *  @param deploymentId the deploymentId
 *
 *  @return an NSArray of all masterLabels
 */
-(NSMutableArray *) masterLabelsForDeployment: (NSInteger) deploymentId {
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:32];
    FMResultSet * rs = [self.db executeQuery:@"SELECT id, name from master_label where deployment_id=?", @(deploymentId)];
    while ([rs next]) {
        NSInteger mlId = [rs intForColumnIndex:0];
        NSString * mlName = [rs stringForColumnIndex:1];
        EUCMasterLabel * masterLabel = [[EUCMasterLabel alloc] init];
        masterLabel.masterLabelID = mlId;
        masterLabel.deploymentID = deploymentId;
        masterLabel.name = mlName;
        [result addObject: masterLabel];
    }
    [rs close];
    
    return result;

}



/**
 *  Removes the master label specified by the passed-in id
 *
 *  @param masterLabelId the id of the master label
 */
-(void) removeMasterLabel: (NSInteger) masterLabelId {
    NSString* sql = @"PRAGMA foreign_keys = ON;";
    [self.db executeUpdate:sql];
    [self.db executeUpdate:@"delete from master_label where id=?", @(masterLabelId)];
}

/**
 *  Renames the master label specified by the passed-in id
 *
 *  @param masterLabelId the id of the master label
 *  @param newName       the new name of the master label
 */
-(void) renameMasterLabel: (NSInteger) masterLabelId toName: (NSString *) newName {
    [self.db executeUpdate:@"update master_label set name=? where id=?", newName, @(masterLabelId)];
}


/**
 *  Add a label to a burst
 *
 *  @param masterLabelId the id of the corresponding master label
 *  @param burstId       the id of the burst to which the label should be added
 *  @param labelLocation a CGPoint representing the x and y location of the label
 *
 *  @return the id of the newly-created label
 */
-(NSInteger) addLabel:(NSInteger)masterLabelId toBurst:(NSInteger)burstId atLocation:(CGPoint)labelLocation {
    NSDictionary * settings = self.settings;
    
    NSString * sql ;
    FMResultSet * rs;
    
    sql = @"select max(id) from label";
    rs = [self.db executeQuery:sql];
    if ([rs next]) {
        NSInteger labelId = [rs intForColumnIndex:0];
        labelId++;
        [rs close];
        [self.db executeUpdate:@"insert into label(id, owner, master_label_id, burst_id, x, y) values(?, ?, ?, ?, ?, ?)",
         @(labelId), settings[@"personId"], @(masterLabelId), @(burstId), @(labelLocation.x), @(labelLocation.y)];
        return labelId;
    }
    return 0;
    
}

/**
 *  Delete the label specified by the passed-in ID
 *
 *  @param labelId the label ID
 */
-(void) deleteLabel: (NSInteger) labelId {
    [self.db executeUpdate:@"delete from label where id=?", @(labelId)];
}


/**
 *  Updates the label identified by the id of the passed in EUCLabel. The x and y location are set based on what the EUCLabel contains
 *
 *  @param label the EUCLabel that contains the id of the label as well as the new x and y locations
 */
-(void) updateLabel: (EUCLabel *) label {
    [self.db executeUpdate:@"Update label set x=?, y=? where id=?",
      @(label.location.x), @(label.location.y), @(label.labelId)];
}

/**
 *  Updates the label identified by the id. The x and y are set based on the passed-in location
 *
 *  @param labelId  the id of the label
 *  @param location the location that needs to be set
 */
-(void) updateLabelWithId:(NSInteger) labelId toLocation: (CGPoint) location {
    [self.db executeUpdate:@"Update label set x=?, y=? where id=?",
     @(location.x), @(location.y), @(labelId)];
}


/**
 *  Returns a list of all labels associated with a burst
 *
 *  @param burstId the burst id
 *
 *  @return An NSMutableArray of NSDictionarys of all labels for that burst
 */
-(NSMutableArray *)labelsForBurst:(NSInteger)burstId {
    NSMutableArray * result = [NSMutableArray arrayWithCapacity:64];
    NSString * sql = @"select l.id, burst_id, x, y, master_label_id, name from label l join master_label m on l.master_label_id = m.id where burst_id = ?";
    FMResultSet * rs = [self.db executeQuery:sql, @(burstId)];
    while ([rs next]) {
        NSInteger labelId = [rs intForColumnIndex:0];
        NSInteger burstId = [rs intForColumnIndex:1];
        NSInteger x = [rs intForColumnIndex:2];
        NSInteger y = [rs intForColumnIndex:3];
        NSInteger masterLabelId = [rs intForColumnIndex:4];
        NSString * name = [rs stringForColumnIndex:5];
        EUCLabel * label = [[EUCLabel alloc] init];
        label.labelId = labelId;
        label.masterLabelId = masterLabelId;
        label.burstId = burstId;
        label.location = CGPointMake(x, y);
        label.name = name;
        
        [result addObject: label];
    }
    [rs close];
    return result;
}

//-(NSMutableArray *)uniqueLabels {
//    NSMutableArray * result = [NSMutableArray arrayWithCapacity:64];
//    NSString * sql = @"select distinct(l.name) from label l ";
//    FMResultSet * rs = [self.db executeQuery:sql];
//    while ([rs next]) {
//        [result addObject:[rs stringForColumnIndex:0]];
//    }
//    [rs close];
//    return result;
//}

//-(NSArray *) labelsForBurst: (NSInteger) burstId; // returns an array of EUCLabel objects
//-(NSArray *) labelsForBurst: (NSInteger) burstId named: (NSString *) labelName;
//-(NSArray *) labelsForDeployment: (NSInteger) deploymentId;
//
//-(void) deleteAllLabelsNamed:(NSString *) labelName onBurst:(NSInteger) burstId;
//-(void) deleteAllLabelsNamed:(NSString *) labelName;
//
//-(void) renameLabelsNamed: (NSString *) oldLabelName toName: (NSString *) newLabelName forBurst: (NSInteger) burstId;
//-(void) renameLabelsNamed: (NSString *) oldLabelName toName: (NSString *) newLabelName forDeployment: (NSInteger) deploymentId;
//

#pragma mark - Labels - notes


/**
 *  Gets a note associated to a burst
 *
 *  @param burstId the id of the burst we are trying to add a note to
 *  @return the note associated with the current burst
 */
-(NSString *) getNoteForBurst: (NSInteger) burstId {
    NSString * sql = @"select label_note from burst where id=?";
    FMResultSet * rs = [self.db executeQuery:sql, @(burstId)];
    if ([rs next]) {
        return [rs stringForColumnIndex:0];
    }
    return NULL;
}

/**
 *  Adds a note to a burst
 *
 *  @param burstId the id of the burst we are trying to add a note to
 *  @param note    the note we need to add
 */
-(void) addNote: (NSString *) note toBurst: (NSInteger) burstId {
    [self.db executeUpdate:@"update burst set label_note=? where id=?", note, @(burstId)];
}

/**
 *  Update a note in a burst
 *
 *  @param burstId the id of the burst whose note we are trying to edit
 *  @param note    the note we need to add
 */
-(void) updateNote: (NSString *) note inBurst: (NSInteger) burstId {
    [self.db executeUpdate:@"update burst set label_note=? where id=?", note, @(burstId)];
}

/**
 *  Delete a note from a burst
 *
 *  @param burstId the id of the burst we are trying to add a note to
 */
-(void) deleteNoteFromBurst: (NSInteger) burstId {
    [self.db executeUpdate:@"update burst set label_note=null where id=?", @(burstId)];
}

#pragma mark - Labels - visited

/**
 *  Returns the visited status of a certain burst
 *
 *  @param burstId the id of the burst
 *  @return the visited status of a burst
 */
-(BOOL) getVisitedForBurst: (NSInteger) burstId {
    NSString * sql = @"select visited from burst where id=?";
    FMResultSet * rs = [self.db executeQuery:sql, @(burstId)];
    if ([rs next]) {
        if ([rs intForColumnIndex:0] == 1)
            return YES;
    }
    return NO;
}


/**
 *  Update visited in a burst
 *
 *  @param burstId the id of the burst whose visitated state we are trying to change
 *  @param status    the visited  status we are trying to set
 */
-(void) updateVisited: (BOOL) status inBurst: (NSInteger) burstId {
    [self.db executeUpdate:@"update burst set visited=? where id=?", @(status ? 1: 0), @(burstId)];
}


@end
