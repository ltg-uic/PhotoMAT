//
//  SetNameContentUIView.h
//  PhotoMat
//
//  Created by Anthony Perritano on 5/1/14.
//  Copyright (c) 2014 Learning Technologies Group. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+NibLoading.h"

@interface SetNameContentUIView : NibLoadedView
@property(weak, nonatomic) IBOutlet UITextView *textView;
@end
