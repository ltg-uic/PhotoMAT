//
//  EUCImportViewController.h
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EUCSelectViewController.h"

@protocol EUCImportDoneDelegate <NSObject>

-(void) importDone: (NSMutableArray *) bursts;

@end

@interface EUCImportViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, EUCSelectionDoneDelegate>

@property (weak, nonatomic) id<EUCImportDoneDelegate> importDoneDelegate;
@end
