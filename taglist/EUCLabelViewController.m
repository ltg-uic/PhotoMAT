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
#import "PhotoTag.h"
#import "PopoverErrorContentViewController.h"
#import "EUCSelectedSet.h"
#import "EUCAppDelegate.h"
#import "EUCDeploymentDetailViewController.h"
#import "EUCBurst.h"
#import "EUCImage.h"
#import "UIUpdateDelegate.h"
#import "EUCDatabase.h"


@interface EUCLabelViewController () <UITextFieldDelegate, OBOvumSource, OBDropZone, UIUpdateDelegate> {
    NSString *lastTagName;
    NSMutableArray *tag_array;
    NSMutableArray *photoTags;
    OBDragDropManager *dragDropManager;
    TagView *selectedTag;
    UIPopoverController *popoverController;
    UIPopoverController *errorPopoverController;
    NSString *currentImageName;
    EUCAppDelegate *appDelegate;
    NSArray *bursts;
    int burstIndex;
}

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet TagList *tagList;
@property(weak, nonatomic) IBOutlet UITextField *addLabelField;
@property(weak, nonatomic) IBOutlet UITextView *noteTextView;
@property(weak, nonatomic) IBOutlet UIView *dropOverlayView;
@property(weak, nonatomic) IBOutlet UIButton *playPauseButton;

@end

NSString *const DELETE_ALL_LABELS = @"DELETE_ALL_LABELS";
NSString *const DELETE_SELECTED_LABEL = @"DELETE_SELECTED_LABEL";

#define MAX_TEXT_CHAR_LENGTH 16
#define MAX_LABELS_ALLOWED 18


@implementation EUCLabelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Labels", "Labels")
                                                        image:[UIImage imageNamed:@"tag.png"]
                                                selectedImage:nil];

//        tag_array = [NSMutableArray arrayWithObjects:@"1234567890qwertyu", @"Ugly Lion", @"grey Squirrel 1", @"yellow green Troll", @"red Dragon", @"fox Gorilla", @"eater Monkey", @"RIT Tigers", @"brown Bunny", @"big fat Rat", @"The yellow Bird1", @"The yellow Bird2", @"The yellow Bird3", @"The yellow Birdees3", @"The yellow Bird3", @"The yellow Bird2", @"the big bad bear2", @"the big bad bear", nil];



        appDelegate = (EUCAppDelegate *) [[UIApplication sharedApplication] delegate];

    }
    return self;
}


- (void)viewDidLoad {


    [self refreshGroupLabel];
    [self createImageBorder];

    //setup textviews
    [self textViewLikeTextField:_noteTextView];
    [_addLabelField setDelegate:self];
    [_addLabelField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    //setup drag and drop
    dragDropManager = [OBDragDropManager sharedManager];
    _dropOverlayView.dropZoneHandler = self;
    //setup gestures for taglist
    [self addGesturesToTagList];
    //create the tag list
    _tagList.maxNumberOfLabels = 18;
    [self refreshLocalBurstCache];
    [_tagList initTagListWithTagNames:tag_array];



}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self refreshGroupLabel];

    [self refreshLocalBurstCache];
}

- (void)refreshGroupLabel {


    EUCSelectedSet *selectedSet = [EUCSelectedSet sharedInstance];
    schoolClassGroupLabel.text = [NSString stringWithFormat:@"%@ : %@ : %@", selectedSet.schoolName, selectedSet.className, selectedSet.groupName];
}

- (void)refreshLocalBurstCache {

    EUCDeploymentDetailViewController *burstDetailController = appDelegate.detail;
    bursts = burstDetailController.importedBursts;

    NSArray *labels = [[EUCDatabase sharedInstance] labelsForDeployment: burstDetailController.deploymentId];

    if( labels.count > 0 ) {
        [tag_array addObjectsFromArray:labels];
    } else {
        tag_array = [NSMutableArray arrayWithObjects:@"", nil];
    }



    photoTags = [[NSMutableArray alloc] init];


    //TODO for testing
    burstIndex = 0;
    EUCBurst *burst = bursts[burstIndex];
    EUCImage *image = burst.images[burstIndex];
    currentImageName = image.filename;
    _imageView.image = [UIImage imageWithContentsOfFile:currentImageName];
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

#pragma mark - Textfield delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (lastTagName == nil ) {
        NSString *newTag = textField.text;
        BOOL SUCCESS = [_tagList addTag:newTag];

        if (SUCCESS) {
            [textField setText:@""];
            lastTagName = nil;
        } else {
            [self showErrorMessageWith:[NSString stringWithFormat:@"Only %d labels are allowed in the list.", MAX_LABELS_ALLOWED] withForView:_addLabelField];
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


            [self changeTagsFrom:lastTagName to:newTagName];
            lastTagName = newTagName;
        }
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
    copy.labelId = [burst addLabelNamed:copy.text atLocation:location];
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
    }
}

- (void)handleDoubleTapTagForOnImage:(UITapGestureRecognizer *)gesture {

    selectedTag = gesture.view;

    lastTagName = selectedTag.text;
    _addLabelField.text = selectedTag.text;

    [self showDeletePopoverWithSelectedTag:selectedTag withFlag:DELETE_SELECTED_LABEL withText:[NSString stringWithFormat:@"Delete %@ Label?", selectedTag.text]];
}

- (IBAction)swipeImagePrevious:(id)sender {

    if (_imageView.isAnimating) {
        [_playPauseButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }

    if (burstIndex >= bursts.count) {
        burstIndex = bursts.count - 1;
    } else {
        burstIndex--;
    }


    //we have another
    if (burstIndex >= 0) {

        [self removeAllTagsFromDragOverlay];

        NSLog(@"left swipe %d", burstIndex);
        EUCBurst *burst = bursts[burstIndex];
        EUCImage *image = burst.images[0];
        currentImageName = image.filename;
        _imageView.image = [UIImage imageWithContentsOfFile:currentImageName];


        NSArray *pts = [photoTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"imageName == %@", currentImageName]];

        if (pts.count > 0) {
            for (PhotoTag *pt in pts) {
                [_dropOverlayView addSubview:pt.tagView];
            }
        }
    }
}

- (IBAction)swipeImageNext:(id)sender {


    if (_imageView.isAnimating) {
        [_playPauseButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }

        burstIndex++;


    //we have another
    if (burstIndex < bursts.count) {

        [self removeAllTagsFromDragOverlay];

        NSLog(@"right swipe %d", burstIndex);
        EUCBurst *burst = bursts[burstIndex];
        EUCImage *image = burst.images[0];
        currentImageName = image.filename;
        _imageView.image = [UIImage imageWithContentsOfFile:currentImageName];

        NSArray *pts = [photoTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"imageName == %@", currentImageName]];


        if (pts.count > 0) {

            for (PhotoTag *pt in pts) {
                [_dropOverlayView addSubview:pt.tagView];
            }
        }

    }


}

- (void)removeAllTagsFromDragOverlay {


    //remove all the tags for this image
    NSArray *pts = [photoTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"imageName == %@", currentImageName]];
    for (PhotoTag *pt in pts) {
        [photoTags removeObject:pt];
    }

    NSArray *subviews = [_dropOverlayView subviews];

    for (UIView *v in subviews) {
        //add them again
        //save it for later
        PhotoTag *pt = [[PhotoTag alloc] init];
        //needs to be dynamic, not hardcoded
        pt.imageName = currentImageName;
        pt.tagView = v;
        pt.xPosition = v.frame.origin.x;
        pt.yPosition = v.frame.origin.y;
        [photoTags addObject:pt];
        [v removeFromSuperview];
    }
}

- (IBAction)playPauseImageAnimation:(id)sender {
    UIButton *btn = (UIButton *) sender;

    if ([_playPauseButton.titleLabel.text isEqualToString:@"Play"]) {
        //[btn setSelected:YES];
        //play

        [_playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];

        EUCBurst *burst = bursts[burstIndex];

        NSMutableArray *ani = [[NSMutableArray alloc] init];
        for (EUCImage *image in burst.images) {
            [ani addObject:[UIImage imageWithContentsOfFile:image.filename]];
        }

        _imageView.animationImages = ani;
        _imageView.animationDuration = 1.0;
        _imageView.animationRepeatCount = 0;
        [_imageView startAnimating];


    } else {
        [_playPauseButton setTitle:@"Play" forState:UIControlStateNormal];

        if (_imageView.isAnimating) {
            [_imageView stopAnimating];

            _imageView.animationImages = nil;
            _imageView.animationDuration = 0;
            _imageView.animationRepeatCount = 0;
        }
    }
}

- (void)shouldUpdateUIWithBursts:(NSMutableArray *)updatedBursts {

    NSLog(@"this shit should update");
}


@end
