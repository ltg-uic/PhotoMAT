//
//  EUCLabelViewController.m
//  TrapEase
//
//  Created by Aijaz Ansari on 3/22/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import <OBDragDrop/OBDragDropManager.h>
#import "EUCLabelViewController.h"
#import "TagList.h"
#import "UIView+OBDropZone.h"
#import "TagView.h"
#import "PopoverTagContentViewController.h"


@interface EUCLabelViewController () <UITextFieldDelegate, OBOvumSource> {
    NSString *lastTagName;
    NSMutableArray *tag_array;
    NSMutableArray *tag_drops;
    OBDragDropManager *dragDropManager;
    NSMutableArray *imageViewLabels;
    TagView *selectedTag;
    UIPopoverController *popoverController;
}

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet TagList *tagList;
@property(weak, nonatomic) IBOutlet UITextField *addLabelField;
@property(weak, nonatomic) IBOutlet UITextView *noteTextView;
@property(weak, nonatomic) IBOutlet UIView *dropOverlayView;

@end

NSString *const DELETE_ALL_LABELS = @"DELETE_ALL_LABELS";
NSString *const DELETE_SELECTED_LABEL = @"DELETE_SELECTED_LABEL";

@implementation EUCLabelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Labels", "Labels")
                                                        image:[UIImage imageNamed:@"tag.png"]
                                                selectedImage:nil];

        tag_array = [NSMutableArray arrayWithObjects:@"Bird", @"Lion", @"Squirrel", @"Troll", @"Dragon", @"Gorilla", @"Monkey", @"Tiger", @"Bunny", @"Rat", nil];
        tag_drops = [[NSMutableArray alloc] init];

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    dragDropManager = [OBDragDropManager sharedManager];
    _dropOverlayView.dropZoneHandler = self;

    [self textViewLikeTextField:_noteTextView];
    [_addLabelField setDelegate:self];
    [_addLabelField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    imageViewLabels = [[NSMutableArray alloc] init];


    [self addGesturesToTagList];
    [_tagList initTagListWithTagNames:tag_array];

    //[_tagList setTagDelegate:self];




}

//uses a block because they need to be added to tagview as the taglist builds them
- (void)addGesturesToTagList {

    void (^gestureAddBlock)(TagView *someView) = ^(TagView *someView) {
        UIGestureRecognizer *dndPan = [dragDropManager createDragDropGestureRecognizerWithClass:[UIPanGestureRecognizer class] source:self];

        [someView addGestureRecognizer:dndPan];

        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleTap:)];
        singleFingerTap.numberOfTapsRequired = 1;
        [someView addGestureRecognizer:singleFingerTap];

        UITapGestureRecognizer *doubleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapTagForInList:)];
        doubleFingerTap.numberOfTapsRequired = 2;
        [someView addGestureRecognizer:doubleFingerTap];

        [singleFingerTap requireGestureRecognizerToFail:doubleFingerTap];

        NSLog(@"block gesture block called");

    };
    _tagList.gestureAddHandler = gestureAddBlock;


}

- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {

    NSLog(@"single tap");

    selectedTag = gesture.view;

    lastTagName = selectedTag.text;
    _addLabelField.text = selectedTag.text;
}

- (void)handleDoubleTapTagForInList:(UITapGestureRecognizer *)gesture {

    NSLog(@"double tap");

    selectedTag = gesture.view;

    lastTagName = selectedTag.text;
    _addLabelField.text = selectedTag.text;

    [self showDeletePopoverWithSelectedTag:selectedTag withFlag:DELETE_ALL_LABELS withText:[NSString stringWithFormat:@"Delete all %@ Labels?", selectedTag.text]];
}

- (void)showDeletePopoverWithSelectedTag:(UIView *)tagView withFlag:(NSString *)flag withText:(NSString *)text {

    PopoverTagContentViewController *content = [[PopoverTagContentViewController alloc] initWithNibName:@"PopoverTagContentViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    content.popoverController = popoverController;

    [content.deleteLabel setText:text];
    popoverController.delegate = self;


    void (^deleteTagHandler)(void) = ^{

        if ([flag isEqualToString:DELETE_ALL_LABELS]) {
            //delete main label
            TagView *t = tagView;
            [_tagList removeTag:t.text];
            //now delete all the ones in the image
            NSArray *overlayTagViews = [_dropOverlayView subviews];
            for (TagView *tv in overlayTagViews) {
                if ([tv.text isEqualToString:t.text]) {
                    [tv removeFromSuperview];
                }
            }
            _addLabelField.text = @"";
        } else if ([flag isEqualToString:DELETE_SELECTED_LABEL]) {
            //deletes a tag off of the imageview
            TagView *t = tagView;
            [t removeFromSuperview];

        }
        NSLog(@"Integer is %@", text);

    };
    content.deleteTagHandler = deleteTagHandler;

    CGRect tagRect = [tagView convertRect:tagView.frame toView:tagView.superview];

    [popoverController setPopoverContentSize:CGSizeMake(424, 99) animated:true];
    [popoverController presentPopoverFromRect:tagView.frame inView:tagView.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    NSString *newTag = textField.text;
    BOOL SUCCESS = [_tagList addTag:newTag];

    if (SUCCESS) {

        if (![tag_drops containsObject:newTag]) {
            [tag_drops addObject:newTag];
        }
        [textField setText:@""];

    }
    [self.view endEditing:YES];
    return YES;

}

- (void)textViewLikeTextField:(UITextView *)textView {
    [textView.layer setBorderColor:[[UIColor colorWithRed:232.0 / 255.0
                                                    green:232.0 / 255.0 blue:232.0 / 255.0 alpha:1] CGColor]];
    [textView.layer setBorderWidth:1.0f];
    [textView.layer setCornerRadius:7.0f];
    [textView.layer setMasksToBounds:YES];
}

#define MAX_LENGTH 9

- (void)textFieldDidChange:(UITextField *)textField {
    NSLog(@"text changed: %@", textField.text);

    NSString *newTagName = textField.text;

    int i = [_tagList indexOfTag:lastTagName];
    if( i >= 0 ) {


        [self changeTagsFrom:lastTagName to:newTagName];
        lastTagName = newTagName;
    }
}

- (void)changeTagsFrom:(NSString *)oldLabel to:(NSString *)newLabel {
    [_tagList changeTagNameFrom:oldLabel to:newLabel];


    NSArray *droppedTags = [_dropOverlayView subviews];

    if (droppedTags.count > 0) {
        for (TagView *tagView in droppedTags) {
            if ([tagView.text isEqualToString:oldLabel]) {
                tagView.text = newLabel;
                [tagView setNeedsDisplay];
            }
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.text.length >= MAX_LENGTH && range.length == 0) {
        return NO; // return NO to not change text
    } else {
        return YES;
    }
}

#pragma mark - OBOvumSource

- (OBOvum *)createOvumFromView:(UIView *)sourceView {
    NSLog(@"source %@ createOvumFromView", sourceView);
    OBOvum *ovum = [[OBOvum alloc] init];
    ovum.dataObject = sourceView.copy;
    return ovum;
}

- (void)ovumDragWillBegin:(OBOvum *)ovum {
    NSLog(@"Ovum<0x%x> %@ ovumDragWillBegin", (int) ovum, ovum.dataObject);
}

- (void)ovumDragEnded:(OBOvum *)ovum {
    NSLog(@"Ovum<0x%x> %@ ovumDragEnded", (int) ovum, ovum.dataObject);
}

- (UIView *)createDragRepresentationOfSourceView:(UIView *)sourceView inWindow:(UIWindow *)window {

    NSLog(@"source %@ createDragRepresentationOfSourceView", sourceView);

    TagView *tagView = (TagView *) sourceView;

    CGRect frame = [sourceView convertRect:sourceView.bounds toView:sourceView.window];
    frame = [window convertRect:frame fromWindow:sourceView.window];

    TagView *dragView = [[TagView alloc] initWithFrame:frame];
    dragView.colorHightlighted = tagView.colorHightlighted;
    dragView.color = tagView.color;
    dragView.text = tagView.text;
    dragView.tag = tagView.tag;

    return dragView;
}


- (void)dragViewWillAppear:(UIView *)dragView inWindow:(UIWindow *)window atLocation:(CGPoint)location {
    NSLog(@"DragViewWillAppear %@", dragView);
    if (dragView != nil ) {
        TagView *tv = dragView;
        lastTagName = tv.text;
        _addLabelField.text = tv.text;
    }

}

#pragma mark - OBDropZone

- (OBDropAction)ovumEntered:(OBOvum *)ovum inView:(UIView *)view atLocation:(CGPoint)location {
    NSLog(@"Ovum<0x%x> %@ Entered", (int) ovum, ovum.dataObject);

    return OBDropActionCopy;
}

- (void)ovumExited:(OBOvum *)ovum inView:(UIView *)view atLocation:(CGPoint)location {
}


- (OBDropAction)ovumMoved:(OBOvum *)ovum inView:(UIView *)view atLocation:(CGPoint)location {
    NSLog(@"Ovum<0x%x> %@ Moved", (int) ovum, ovum.dataObject);

    return OBDropActionCopy;
}


- (void)ovumDropped:(OBOvum *)ovum inView:(UIView *)view atLocation:(CGPoint)location {
    NSLog(@"Ovum<0x%x> %@ Dropped", (int) ovum, ovum.dataObject);

    TagView *tagView = ovum.dataObject;

    tagView.center = location;

    TagView *copy = tagView.copy;

    [self enableImageViewGesturesOnTagView:copy];


    [_dropOverlayView addSubview:copy];
    [imageViewLabels addObject:copy];
}

- (void)enableImageViewGesturesOnTagView:(TagView *)tagView {
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [tagView addGestureRecognizer:pgr];

    UITapGestureRecognizer *doubleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapTagForOnImage:)];
    doubleFingerTap.numberOfTapsRequired = 2;
    [tagView addGestureRecognizer:doubleFingerTap];
}

//Once dropped we are in a different world. Lets just move it around.
- (void)handlePan:(UIPanGestureRecognizer *)gesture {

    static CGRect originalFrame;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        originalFrame = gesture.view.frame;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translate = [gesture translationInView:gesture.view.superview];
        CGRect newFrame = CGRectMake(fmin(gesture.view.superview.frame.size.width - originalFrame.size.width, fmax(originalFrame.origin.x + translate.x, 0.0)),
                fmin(gesture.view.superview.frame.size.height - originalFrame.size.height, fmax(originalFrame.origin.y + translate.y, 0.0)),
                originalFrame.size.width,
                originalFrame.size.height);

        gesture.view.frame = newFrame;
    }
}

- (void)handleDoubleTapTagForOnImage:(UITapGestureRecognizer *)gesture {

    selectedTag = gesture.view;

    lastTagName = selectedTag.text;
    _addLabelField.text = selectedTag.text;

    [self showDeletePopoverWithSelectedTag:selectedTag withFlag:DELETE_SELECTED_LABEL withText:[NSString stringWithFormat:@"Delete %@ Label?", selectedTag.text]];
}

@end
