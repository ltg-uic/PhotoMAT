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
    
    NSString * sql = @"SELECT versionNumber from trapDatabaseVersion";
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


@end
