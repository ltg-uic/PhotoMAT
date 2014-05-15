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
#import "PopoverErrorContentViewController.h"
#import "EUCSelectedSet.h"
#import "EUCAppDelegate.h"
#import "EUCDeploymentDetailViewController.h"
#import "EUCBurst.h"
#import "EUCImage.h"
#import "EUCDatabase.h"
#import "EUCLabel.h"
#import "EUCMasterLabel.h"
#import "TimelineView.h"
#import "CountPickerViewController.h"


@interface EUCLabelViewController () <UITextFieldDelegate, UITextViewDelegate, OBOvumSource, OBDropZone> {
    NSString *lastTagName;
    NSMutableArray *tag_array;
    NSMutableArray *photoTags;
    OBDragDropManager *dragDropManager;
    TagView *selectedTag;
    UIPopoverController *popoverController;
    UIPopoverController *errorPopoverController;
    NSString *currentImageName;
    EUCAppDelegate *appDelegate;
    NSMutableArray *bursts;
    int burstIndex;
    NSInteger deploymentId;
    int highlightedImageIndex;
}

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet TagList *tagList;
@property(weak, nonatomic) IBOutlet UITextField *addLabelField;
@property(weak, nonatomic) IBOutlet UITextView *noteTextView;
@property(weak, nonatomic) IBOutlet UIView *dropOverlayView;
@property(weak, nonatomic) IBOutlet TimelineView *timelineView;

@end

NSString *const DELETE_ALL_LABELS = @"DELETE_ALL_LABELS";
NSString *const DELETE_SELECTED_LABEL = @"DELETE_SELECTED_LABEL";


#define MAX_TEXT_CHAR_LENGTH 16
#define MAX_LABELS_ALLOWED 12


@implementation EUCLabelViewController {
    NSDateFormatter *dateformat;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Labels", "Labels")
                                                        image:[UIImage imageNamed:@"tag.png"]
                                                selectedImage:nil];


        appDelegate = (EUCAppDelegate *) [[UIApplication sharedApplication] delegate];

        dateformat = [[NSDateFormatter alloc] init];
        [dateformat setDateFormat:@"hh:mm:ss a M/d/Y"];

    }
    return self;
}


- (void)viewDidLoad {


    [self refreshGroupLabel];
    [self createImageBorder];

    //setup textviews
    [self textViewLikeTextField:_noteTextView];
    [_noteTextView setDelegate:self];
    [_addLabelField setDelegate:self];
    _timelineView.timelineDelegate = self;
    [_addLabelField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    //setup drag and drop
    dragDropManager = [OBDragDropManager sharedManager];
    _dropOverlayView.dropZoneHandler = self;
    //setup gestures for taglist
    [self addGesturesToTagList];
    //create the tag list
    _tagList.maxNumberOfLabels = 12;
    [self refreshLocalBurstCache];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//
    [self refreshGroupLabel];
//
    [self refreshLocalBurstCache];
}

- (void)refreshGroupLabel {
    EUCSelectedSet *selectedSet = [EUCSelectedSet sharedInstance];
    schoolClassGroupLabel.text = [NSString stringWithFormat:@"%@ : %@ : %@", selectedSet.schoolName, selectedSet.className, selectedSet.groupName];
    _cameraLabel.text = [NSString stringWithFormat:@"%@", selectedSet.deploymentName];
}


- (void)refreshLocalBurstCache {

    [self removeAllTagsFromDragOverlay];

    _addLabelField.text = @"";
    lastTagName = nil;
    EUCDeploymentDetailViewController *burstDetailController = appDelegate.detail;
    bursts = burstDetailController.importedBursts;

    for (EUCBurst *aBurst in bursts) {
        aBurst.highlighted = NO;
    }

    deploymentId = burstDetailController.deploymentId;

    NSArray *labels = [[EUCDatabase sharedInstance] masterLabelsForDeployment:burstDetailController.deploymentId];

    tag_array = [[NSMutableArray alloc] init];
    if (labels.count > 0) {
        for (EUCMasterLabel *label in labels) {
            [_tagList addTag:label.name withLabelId:label.masterLabelID];
        }
    } else {
        tag_array = nil;
    }


    //TODO for testing
    burstIndex = 0;
    EUCBurst *burst = bursts[burstIndex];

    //visited
    burst.highlighted = YES;
    [burst setHasBeenVisited:YES];
    bursts[burstIndex] = burst;

    [self updateTimelineWithBurstHighlightingBursts:bursts];
    [self updatePhotoLabels:burst];


    NSString *note = [[EUCDatabase sharedInstance] getNoteForBurst:burst.burstId];

    if (note != nil ) {
        _noteTextView.text = note;
    }


    [self addLabelsToDropOverlay:burst];

    highlightedImageIndex = 0;

    [self playAnimation];
}

- (void)updatePhotoLabels:(EUCBurst *)burst {
    _timestampLabel.text = [dateformat stringFromDate:burst.date];

    [self changeCountLabel:[NSString stringWithFormat:@"%d/%d", burstIndex + 1, bursts.count]];
}

- (void)changeCountLabel:(NSString *)title {
    [_countLabel setTitle:title forState:UIControlStateNormal];
    [_countLabel setTitle:title forState:UIControlStateHighlighted];
    [_countLabel setTitle:title forState:UIControlStateSelected];
}

- (void)createImageBorder {
    CALayer *layer = _imageView.layer;
    [layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [layer setBorderWidth:8.0f];
    [layer setShadowColor:[[UIColor blackColor] CGColor]];
    [layer setShadowOpacity:0.3f];
    [layer setShadowOffset:CGSizeMake(1, 3)];
    [layer setShadowRadius:4.0];
    [_imageView setClipsToBounds:NO];
}

//changes the look of the textfield
- (void)textViewLikeTextField:(UITextView *)textView {
    [textView.layer setBorderColor:[[UIColor colorWithRed:232.0 / 255.0
                                                    green:232.0 / 255.0 blue:232.0 / 255.0 alpha:1] CGColor]];
    [textView.layer setBorderWidth:1.0f];
    [textView.layer setCornerRadius:7.0f];
    [textView.layer setMasksToBounds:YES];
}
#pragma mark - Save Note

- (void)saveNote {

    if (burstIndex >= 0 && burstIndex < bursts.count) {
        EUCBurst *burst = bursts[burstIndex];

        [[EUCDatabase sharedInstance] addNote:_noteTextView.text toBurst:burst.burstId];
    }

}


#pragma mark - UITextView delegates

- (void)textViewDidEndEditing:(UITextView *)textView {

    [self saveNote];
}

#pragma mark - Textfield delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (lastTagName == nil ) {
        NSString *newTag = textField.text;


        BOOL DUP = [_tagList isDuplicateTag:newTag];

        if (DUP) {
            return YES;
        } else {
            NSInteger labelId = [[EUCDatabase sharedInstance] addMasterLabel:newTag toDeployment:deploymentId];
            BOOL SUCCESS = [_tagList addTag:newTag withLabelId:labelId];

            if (SUCCESS) {
                [textField setText:@""];
                lastTagName = nil;
            } else {
                [self showErrorMessageWith:[NSString stringWithFormat:@"Only %d labels are allowed in the list.", MAX_LABELS_ALLOWED] withForView:_addLabelField];
            }


        }


    }
    [self.view endEditing:YES];
    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField {
    NSLog(@"text changed: %@", textField.text);

    NSString *newTagName = textField.text;

    if (lastTagName != nil ) {
        int i = [_tagList indexOfTag:lastTagName];
        if (i >= 0) {

            NSInteger labelId = [self changeTagsFrom:lastTagName to:newTagName];

            if (labelId != -1) {
                [[EUCDatabase sharedInstance] renameMasterLabel:labelId toName:newTagName];
                lastTagName = newTagName;
            }

        }
    }
}

- (NSInteger)changeTagsFrom:(NSString *)oldLabel to:(NSString *)newLabel {
    NSInteger foundLabelId = [_tagList changeTagNameFrom:oldLabel to:newLabel];


    NSArray *droppedTags = [_dropOverlayView subviews];

    if (droppedTags.count > 0) {
        for (TagView *tagView in droppedTags) {
            if ([tagView.text isEqualToString:oldLabel]) {
                tagView.text = newLabel;
                [tagView setNeedsDisplay];
            }
        }
    }
    return foundLabelId;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField.text.length >= MAX_TEXT_CHAR_LENGTH && range.length == 0) {
        return NO; // return NO to not change text
    } else {
        return YES;
    }
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    lastTagName = nil;
    textField.text = @"";
    return YES;
}

#pragma mark - Popovers

- (void)showErrorMessageWith:(NSString *)errorMessage withForView:(UIView *)targetView {
    PopoverErrorContentViewController *content = [[PopoverErrorContentViewController alloc] initWithNibName:@"PopoverErrorContentViewController" bundle:nil];


    errorPopoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    content.messageLabel.text = errorMessage;

    [errorPopoverController setPopoverContentSize:CGSizeMake(380, 68) animated:true];
    [errorPopoverController presentPopoverFromRect:targetView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];


}

- (void)showDeletePopoverWithSelectedTag:(UIView *)tagView withFlag:(NSString *)flag withText:(NSString *)text {

    PopoverTagContentViewController *content = [[PopoverTagContentViewController alloc] initWithNibName:@"PopoverTagContentViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    content.popoverController = popoverController;

    [content.deleteLabel setText:text];


    void (^deleteTagHandler)(void) = ^{

        if ([flag isEqualToString:DELETE_ALL_LABELS]) {
            //delete main label
            TagView *t = (TagView *) tagView;
            [[EUCDatabase sharedInstance] removeMasterLabel:t.labelId];

            [_tagList removeTag:t.text];
            lastTagName = nil;
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

            TagView *t = (TagView *) tagView;

            [[EUCDatabase sharedInstance] deleteLabel:t.labelId];
            [t removeFromSuperview];

        }
        NSLog(@"Integer is %@", text);

    };
    content.deleteTagHandler = deleteTagHandler;
    [popoverController setPopoverContentSize:CGSizeMake(424, 99) animated:true];
    [popoverController presentPopoverFromRect:tagView.frame inView:tagView.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
    [self enableDropColor:copy];

    EUCBurst *burst = bursts[burstIndex];
    copy.labelId = [burst addLabelId:copy.labelId atLocation:location];
    [_dropOverlayView addSubview:copy];

}


- (void)enableDropColor:(TagView *)tagView {
    [tagView setColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.6]];

}

- (void)enableImageViewGesturesOnTagView:(TagView *)tagView {
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [tagView addGestureRecognizer:pgr];

    UITapGestureRecognizer *doubleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapTagForOnImage:)];
    doubleFingerTap.numberOfTapsRequired = 2;
    [tagView addGestureRecognizer:doubleFingerTap];
}

#pragma mark - Gestures

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

    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        TagView *tv = (TagView *) gesture.view;
        EUCBurst *eucBurst = bursts[burstIndex];

        [eucBurst updateLabelWithId:tv.labelId toLocation:tv.center];
    }
}

- (void)handleDoubleTapTagForOnImage:(UITapGestureRecognizer *)gesture {

    selectedTag = gesture.view;

    lastTagName = selectedTag.text;
    _addLabelField.text = selectedTag.text;

    [self showDeletePopoverWithSelectedTag:selectedTag withFlag:DELETE_SELECTED_LABEL withText:[NSString stringWithFormat:@"Delete %@ Label?", selectedTag.text]];
}

- (IBAction)swipeImagePrevious:(id)sender {

    [self saveNote];
//    if (_imageView.isAnimating) {
//        [_playPauseButton sendActionsForControlEvents:UIControlEventTouchUpInside];
//    }

    burstIndex--;

    BOOL exists = burstIndex >= 0 ? YES : NO;

    if (exists == NO) {
        burstIndex++;
    } else {
        [self removeAllTagsFromDragOverlay];

        NSLog(@"right swipe %d", burstIndex);


        //previous burst
        BOOL hasNext = burstIndex + 1 < bursts.count ? YES : NO;

        if (hasNext) {
            EUCBurst *burst = bursts[burstIndex + 1];
            burst.hasBeenVisited = YES;
            burst.highlighted = NO;
            bursts[burstIndex + 1] = burst;
        }

        //current burst
        EUCBurst *burst = bursts[burstIndex];
        burst.hasBeenVisited = YES;
        burst.highlighted = YES;
        bursts[burstIndex] = burst;

        [self updateTimelineWithBurstHighlightingBursts:bursts];

        [self updatePhotoLabels:burst];

        NSString *note = [[EUCDatabase sharedInstance] getNoteForBurst:burst.burstId];

        _noteTextView.text = note;


        BOOL wasPlaying = [self pauseAnimation];

        [self addLabelsToDropOverlay:burst];

        highlightedImageIndex = 0;

        if (wasPlaying)
            [self playAnimation];


    }
}

- (void)jumpToImageWithIndex:(int)newBurstIndex {

    [self saveNote];
    [self removeAllTagsFromDragOverlay];

    //previous index
    EUCBurst *oldBurst = bursts[burstIndex];
    [oldBurst setHasBeenVisited:YES];
    oldBurst.highlighted = NO;
    bursts[burstIndex] = oldBurst;


    burstIndex = newBurstIndex;

    BOOL exists = burstIndex < [bursts count] ? YES : NO;

    if (exists == NO) {
        burstIndex--;
    }

    //current burst
    EUCBurst *burst = bursts[burstIndex];
    [burst setHasBeenVisited:YES];
    burst.highlighted = YES;


    bursts[burstIndex] = burst;

    _imageView.image = nil;
    [self updatePhotoLabels:burst];


    NSString *note = [[EUCDatabase sharedInstance] getNoteForBurst:burst.burstId];

    _noteTextView.text = note;

    [self updateTimelineWithBurstHighlightingBursts:bursts];

    BOOL wasPlaying = [self pauseAnimation];

    [self addLabelsToDropOverlay:burst];

    highlightedImageIndex = 0;

    if (wasPlaying)
        [self playAnimation];


}

- (IBAction)swipeImageNext:(id)sender {
    [self saveNote];

//    if (_imageView.isAnimating) {
//        [_playPauseButton sendActionsForControlEvents:UIControlEventTouchUpInside];
//    }

    burstIndex++;

    BOOL exists = burstIndex < [bursts count] ? YES : NO;

    if (exists == NO) {
        burstIndex--;
    } else {


        [self removeAllTagsFromDragOverlay];

        NSLog(@"right swipe %d", burstIndex);


        //previous burst
        BOOL hasPrevious = burstIndex - 1 > -1 ? YES : NO;

        if (hasPrevious) {
            EUCBurst *burst = bursts[burstIndex - 1];
            [burst setHasBeenVisited:YES];
            burst.highlighted = NO;
            bursts[burstIndex - 1] = burst;
        }

        //current burst
        EUCBurst *burst = bursts[burstIndex];
        [burst setHasBeenVisited:YES];
        burst.highlighted = YES;


        bursts[burstIndex] = burst;

        _imageView.image = nil;
        [self updatePhotoLabels:burst];


        NSString *note = [[EUCDatabase sharedInstance] getNoteForBurst:burst.burstId];

        _noteTextView.text = note;

        [self updateTimelineWithBurstHighlightingBursts:bursts];

        BOOL wasPlaying = [self pauseAnimation];

        [self addLabelsToDropOverlay:burst];

        highlightedImageIndex = 0;

        if (wasPlaying)
            [self playAnimation];


    }

}

- (void)playAnimation {

    if (burstIndex >= 0 && burstIndex < bursts.count) {
        EUCBurst *burst = bursts[burstIndex];


        _imageView.highlighted = NO;


        highlightedImageIndex++;


        [_imageView startAnimating];

        [_animateButton setTitle:@"Pause" forState:UIControlStateNormal];

    }
}

- (BOOL)pauseAnimation {
    if (_imageView.isAnimating) {
        [_imageView stopAnimating];

        //_imageView.animationImages = nil;
//        _imageView.animationDuration = 0;
//        _imageView.animationRepeatCount = 0;
        _imageView.highlighted = YES;


        EUCBurst *currentBurst = bursts[burstIndex];

        if (highlightedImageIndex >= currentBurst.images.count) {
            highlightedImageIndex = 0;
        }

        EUCImage *image = currentBurst.images[highlightedImageIndex];

        _imageView.highlightedImage = [UIImage imageWithContentsOfFile:image.filename];


        [_animateButton setTitle:@"Play" forState:UIControlStateNormal];

        return YES;
    }
    return NO;
}

- (void)updateTimelineWithBurstHighlightingBursts:(NSMutableArray *)array {
    _timelineView.bursts = bursts;
    [_timelineView setNeedsDisplay];
}

- (void)addLabelsToDropOverlay:(EUCBurst *)burst {
    EUCImage *image = burst.images[0];
    currentImageName = image.filename;
    _imageView.image = [UIImage imageWithContentsOfFile:currentImageName];
    _imageView.highlightedImage = [UIImage imageWithContentsOfFile:currentImageName];

    NSMutableArray *ani = [[NSMutableArray alloc] init];
    for (EUCImage *image in burst.images) {
        [ani addObject:[UIImage imageWithContentsOfFile:image.filename]];
    }

    _imageView.animationImages = ani;
    _imageView.animationDuration = 3;
    _imageView.animationRepeatCount = 0;

    NSMutableArray *labels = [[EUCDatabase sharedInstance] labelsForBurst:burst.burstId];

    for (EUCLabel *l in labels) {
        TagView *tv = [_tagList createDropTagView:l.name withLabelId:l.labelId];
        [self enableImageViewGesturesOnTagView:tv];
        [self enableDropColor:tv];
        [_dropOverlayView addSubview:tv];
        tv.center = l.location;
    }


}

- (void)removeAllTagsFromDragOverlay {

    NSArray *subviews = [_dropOverlayView subviews];

    for (UIView *v in subviews) {
        [v removeFromSuperview];
    }
}


- (void)currentDeploymentIdSetTo:(NSInteger)deploymentId {

    [_tagList clearList];

//    [self refreshGroupLabel];
//
//    [self refreshLocalBurstCache];
}

#pragma mark - Animation

- (IBAction)animateButton:(id)sender {
    if ([_animateButton.titleLabel.text isEqualToString:@"Play"]) {


        [self playAnimation];
    } else {

        [self pauseAnimation];
    }
}


- (IBAction)changeCountAction:(id)sender {
    CountPickerViewController *content = [[CountPickerViewController alloc] initWithNibName:@"CountPickerViewController" bundle:nil];

    popoverController = [[UIPopoverController alloc]
            initWithContentViewController:content];

    //popoverController = self;
    content.somePopoverController = popoverController;
    content.modalInPopover = YES;


    NSMutableArray *burstIndexes = [[NSMutableArray alloc] init];

    for (int i = 0; i < bursts.count; i++) {
        [burstIndexes addObject:[@(i + 1) stringValue]];
    }

    content.burstIndexes = burstIndexes;
    [content selectRow:burstIndex];

    void (^finishedHandler)(NSString *) = ^(NSString *newBurstIndex) {


        [self changeCountLabel:[NSString stringWithFormat:@"%d/%d", burstIndex + 1, bursts.count]];

        [self jumpToImageWithIndex:[newBurstIndex intValue] - 1];

    };
    content.finishedHandler = finishedHandler;
    [popoverController setPopoverContentSize:CGSizeMake(180, 200) animated:true];
    CGRect buttonRect = [_countLabel convertRect:_countLabel.frame toView:self.view];

    [popoverController presentPopoverFromRect:_countLabel.frame inView:_countLabel.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)didSelectBurstIndexFromTap:(int)selectedBurstIndex {
    [self jumpToImageWithIndex:selectedBurstIndex];
}

@end
