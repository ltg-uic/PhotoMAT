//
//  EUCBurst.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/27/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCBurst.h"
#import "EUCLabel.h"
#import "EUCDatabase.h"

@implementation EUCBurst

- (instancetype)init
{
    self = [super init];
    if (self) {
        _images = [[NSMutableArray alloc] initWithCapacity:6];
        _selected = YES;
    }
    return self;
}

#pragma mark - labels
-(void) addLabel: (EUCLabel *) label {
    [self.labels addObject:label];
    NSInteger labelId = [[EUCDatabase sharedInstance] addLabel:label.name toBurst:self.burstId atLocation:label.location];
    label.labelId = labelId;
}

-(void) addLabelNamed: (NSString *) labelName atLocation: (CGPoint) location {
    EUCLabel * label = [[EUCLabel alloc] init];
    label.name = labelName;
    label.location = location;
    [self addLabel:label];
}


-(void) addLabels: (NSArray *) labelArray {
    for (EUCLabel * label in labelArray) {
        [self addLabel:label];
    }
}

-(void) deleteLabel: (EUCLabel *) label {
    NSMutableArray * labelsToDelete = [NSMutableArray arrayWithCapacity:[self.labels count]];
    
    for (EUCLabel * existingLabel in self.labels) {
        if ([label.name isEqualToString: existingLabel.name] &&
            CGPointEqualToPoint(label.location, existingLabel.location)
            ) {
            // delete this label
            [labelsToDelete addObject:existingLabel];
        }
    }
    for (EUCLabel * label in labelsToDelete) {
        [self.labels removeObject:label];
        [[EUCDatabase sharedInstance] deleteLabel:label.labelId];
    }
}

-(void) deleteLabelNamed: (NSString *) labelName {
    NSMutableArray * labelsToDelete = [NSMutableArray arrayWithCapacity:[self.labels count]];
    
    for (EUCLabel * existingLabel in self.labels) {
        if ([labelName isEqualToString: existingLabel.name]) {
            [labelsToDelete addObject:existingLabel];
        }
    }
    for (EUCLabel * label in labelsToDelete) {
        [self.labels removeObject:label];
        [[EUCDatabase sharedInstance] deleteLabel:label.labelId];
    }
    

}

-(void) deleteLabels: (NSArray *) labelArray {
    
    for (EUCLabel * label in labelArray) {
        [self.labels removeObject:label];
        [[EUCDatabase sharedInstance] deleteLabel:label.labelId];
    }
}

-(void) deleteAllLabels {
    for (EUCLabel * label in self.labels) {
        [[EUCDatabase sharedInstance] deleteLabel:label.labelId];
    }
    [self.labels removeAllObjects];
}

-(void) saveLabelLocation: (EUCLabel *) label {
    [[EUCDatabase sharedInstance] updateLabel: label];
}

-(void) updateLabel: (EUCLabel *) label location: (CGPoint) location {
    label.location = location;
    [self saveLabelLocation: label];
}

-(void) updateLabelNamed: (NSString *) labelName location: (CGPoint) location {
    for (EUCLabel * existingLabel in self.labels) {
        if ([labelName isEqualToString: existingLabel.name]) {
            [self saveLabelLocation:existingLabel];
        }
    }
}

-(void) renameLabelNamed: (NSString *) oldName toName: (NSString *) newName {
    for (EUCLabel * existingLabel in self.labels) {
        if ([oldName isEqualToString: existingLabel.name]) {
            existingLabel.name = newName;
            [[EUCDatabase sharedInstance] updateLabel:existingLabel];
        }
    }
}

@end
