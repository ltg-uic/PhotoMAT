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

@interface EUCDatabase ()
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

#pragma mark - deployments

-(NSArray *) getDeployments {
    NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity:64];
    
    NSString * sql = @"select names, deployment_date from deployment order by deployment_date desc";
    
    FMResultSet * rs = [self.db executeQuery:sql];
    
    while ([rs next]) {
        NSDictionary * row = @{@"names": [rs stringForColumnIndex:0],
                               @"date": [rs stringForColumnIndex:1]
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
    
    NSMutableArray * people = [[NSMutableArray alloc] initWithCapacity:8];
    for (NSDictionary * person in deployment[@"person"]) {
        [people addObject:person[@"first_name"]];
    }
    NSString * names = [people componentsJoinedByString:@", "];
    
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
    
    [cols addObject:@"names"];
    [vals addObject:names];
    
    [self insertColumns:cols andValues:vals intoTable:@"deployment"];
}


-(void) clearTable: (NSString *) tableName {
    [self.db executeUpdate:[NSString stringWithFormat:@"delete from %@", tableName]];
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
