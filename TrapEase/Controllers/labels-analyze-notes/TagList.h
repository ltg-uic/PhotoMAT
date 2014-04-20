//
//  TagList.h
//  ios_tag_list
//
//  Created by Maxim on 9/23/13.
//  Copyright (c) 2013 Maxim. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TagView;

@interface TagList : UIScrollView {


}

@property(nonatomic, copy) void (^gestureAddHandler)(TagView *someView);
@property(nonatomic) int maxNumberOfLabels;


- (id)initWithX:(CGFloat)x withY:(CGFloat)y;

- (void)initTagListWithTagNames:(NSMutableArray *)tagTexts;

- (void)addTagGesture:(UIGestureRecognizer *)gesture;

- (void)setPosX:(CGFloat)x andY:(CGFloat)y;

- (void)clearList;

- (BOOL)isDuplicateTag:(NSString *)tagName;

- (TagView *)createDropTagView:(NSString *)tagName withLabelId:(NSInteger)labelId;

- (BOOL)addTag:(NSString *)tagName withLabelId:(NSInteger)labelId;

- (int)indexOfTag:(NSString *)tagName;

- (BOOL)removeTag:(NSString *)tagName;


- (NSInteger)changeTagNameFrom:(NSString *)oldLabel to:(NSString *)newLabel;
@end
