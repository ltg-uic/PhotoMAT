//
//  EUCBurst.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EUCLabel;

@interface EUCBurst : NSObject

@property (assign, nonatomic) NSInteger burstId;
@property (strong, nonatomic) NSMutableArray *images;
@property (assign, nonatomic) BOOL selected;
@property (assign, nonatomic) BOOL highlighted;
@property (assign, nonatomic) BOOL hasBeenVisited;


@property (strong, nonatomic) NSMutableArray *labels;
@property (strong, nonatomic) NSDate * date;

#pragma mark - labels

// These are the only two used methods
-(NSInteger)addLabelId:(NSInteger)labelId atLocation: (CGPoint) location;
- (void)updateLabelWithId:(NSInteger)labelId toLocation:(CGPoint)location;

// The following methods are never used
-(NSInteger) addLabel: (EUCLabel *) label;
-(void) addLabels: (NSArray *) labelArray;
-(void) deleteLabel: (EUCLabel *) label;
-(void) deleteLabelNamed: (NSString *) labelName;
-(void) deleteLabels: (NSArray *) labelArray;
-(void) deleteAllLabels;
-(void) saveLabelLocation: (EUCLabel *) label;
-(void) updateLabel: (EUCLabel *) label location: (CGPoint) location;
-(void) updateLabelNamed: (NSString *) labelName location: (CGPoint) location;
-(void) renameLabelNamed: (NSString *) oldName toName: (NSString *) newName;

@end
