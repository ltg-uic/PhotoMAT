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

static EUCDatabase * database;
static const int ddLogLevel = LOG_LEVEL_INFO;

#define kDBFileName @"trap.db"
#define kDBBaseName @"trap"

@interface EUCDatabase () {
    NSDictionary * _settings;
}
@property (strong, nonatomic) FMDatabase * db;
@end

@implementation EUCDatabase

+(EUCDatabase *) sharedInstance {
    if (database == nil) {
        database = [[EUCDatabase alloc] init];
        [database openDatabase];
    }
    return database;
}

-(EUCDatabase *) init {
    if (self = [super init]) {
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
            [self saveClass: classRoom];
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
    NSString * sql = @"select id, name from school order by name";
    FMResultSet * rs = [self.db executeQuery:sql];
    while ([rs next]) {
        NSInteger schoolId = [rs intForColumnIndex:0];
        
        NSMutableDictionary * row = [NSMutableDictionary dictionaryWithCapacity:3];
        row[@"id"] = @(schoolId);
        row[@"name"] = [rs stringForColumnIndex:1];
        row[@"class"] = [self classRoomsForSchool: schoolId];
        
        [array addObject:row];
    }
    
    return array;
}

-(NSArray *) classRoomsForSchool: (NSInteger) schoolId {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:8];
    NSString * sql = @"select id, name from class where school_id = ? order by name";
    FMResultSet * rs = [self.db executeQuery:sql, @(schoolId)];
    while ([rs next]) {
        NSInteger classId = [rs intForColumnIndex:0];
        
        NSMutableDictionary * row = [NSMutableDictionary dictionaryWithCapacity:3];
        row[@"id"] = @(classId);
        row[@"name"] = [rs stringForColumnIndex:1];
        row[@"person"] = [self personsForClass: classId];
        
        [array addObject:row];
    }
    
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
    
    return array;
}

#pragma mark - deployments

-(NSArray *) getDeployments {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:64];
    
    NSString * sql = @"select person_name, deployment_date, school_name, class_name, short_name, id from deployment order by deployment_date desc";
    
    FMResultSet * rs = [self.db executeQuery:sql];
    
    while ([rs next]) {
        
        NSDictionary * row = @{@"person_name": [rs stringForColumnIndex:0],
                               @"date": [rs stringForColumnIndex:1],
                               @"school_name": [rs stringForColumnIndex:2],
                               @"class_name": [rs stringForColumnIndex:3],
                               @"short_name": [rs stringForColumnIndex:4],
                               @"id": @([rs intForColumnIndex:5])
                               };
        
        [array addObject:row];
    }
    [rs close];
    
    return [NSArray arrayWithArray:array];
    
}

-(void) refreshDeployments: (NSArray *) deployments {
    
    [self clearTable: @"tag"];
    [self clearTable:@"image"];
    [self clearTable:@"burst"];
    [self clearTable:@"deployment_picture"];
    [self clearTable:@"deployment"];
    
    for (NSDictionary * deployment in deployments) {
        [self saveDeployment: deployment];
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
    
    [self insertColumns:cols andValues:vals intoTable:@"deployment"];
}


-(void) clearTable: (NSString *) tableName {
    [self.db executeUpdate:[NSString stringWithFormat:@"delete from %@", tableName]];
}


-(NSDictionary *) getDeploymentRecord:(NSNumber *)deploymentId {
    NSString * sql = @"select deployment_date, notes, short_name, actual_mark_time, camera_trap_number from deployment where id=?";
    
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


@end
