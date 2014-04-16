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

@property (strong, nonatomic) NSMutableArray *labels;


#pragma mark - labels

-(void) addLabel: (EUCLabel *) label;
-(void) addLabelNamed: (NSString *) labelName atLocation: (CGPoint) location;
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
