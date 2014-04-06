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


@interface EUCLabelViewController () <UITextFieldDelegate,OBOvumSource> {
    NSString *lastLabel;
    NSMutableArray *tag_array;
    OBDragDropManager *dragDropManager;
    NSMutableArray *imageViewLabels;
    TagView *selectedTag;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet TagList *tagList;
@property (weak, nonatomic) IBOutlet UITextField *addLabelField;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;
@property (weak, nonatomic) IBOutlet UIView *dropOverlayView;

@end

@implementation EUCLabelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Labels", "Labels")
                                                        image:[UIImage imageNamed:@"tag.png"]
                                                selectedImage:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self textViewLikeTextField:_noteTextView];
    [_addLabelField setDelegate:self];
    [_addLabelField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    imageViewLabels = [[NSMutableArray alloc] init];

    tag_array = [NSMutableArray arrayWithObjects:@"Bird", @"Lion", @"Squirrel", @"Troll", @"Dragon", @"Gorilla", @"Monkey", @"Tiger", @"Bunny", @"Rat", nil];

    [_tagList createTags:tag_array];
    [_tagList setTagDelegate:self];
    _dropOverlayView.dropZoneHandler = self;

    dragDropManager = [OBDragDropManager sharedManager];

    [self addGestures];


}

-(void) addGestures {
    NSArray *subviews = _tagList.subviews;
    for( TagView *tagView in subviews ) {
        UIGestureRecognizer *recognizer = [dragDropManager createDragDropGestureRecognizerWithClass:[UIPanGestureRecognizer class] source:self];
        [tagView addGestureRecognizer:recognizer];

        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleTap:)];
        [tagView addGestureRecognizer:singleFingerTap];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {
    selectedTag = gesture.view;
    
    lastLabel = selectedTag.text;
    _addLabelField.text = selectedTag.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{

    int i = [tag_array indexOfObject:lastLabel];
    if( i >= 0 ) {
         [self.view endEditing:YES];
         return NO;
    } else {
        [tag_array addObject:[textField text]];

        [_tagList createTags:tag_array];
        [self addGestures];
        [textField setText:@""];

        return YES;
    }

    return NO;


}

-(void) textViewLikeTextField:(UITextView*)textView
{
    [textView.layer setBorderColor:[[UIColor colorWithRed:232.0/255.0
                                                    green:232.0/255.0 blue:232.0/255.0 alpha:1] CGColor]];
    [textView.layer setBorderWidth:1.0f];
    [textView.layer setCornerRadius:7.0f];
    [textView.layer setMasksToBounds:YES];
}

#define MAX_LENGTH 9

-(void)textFieldDidChange :(UITextField *)textField{
    NSLog( @"text changed: %@", textField.text);


    int i = [tag_array indexOfObject:lastLabel];
    if( i >= 0 ) {
        NSString *newLabel = textField.text;
        [tag_array replaceObjectAtIndex:i withObject:newLabel];
        [_tagList createTags:tag_array];

        [self changeDraggedTagsFrom:lastLabel to:newLabel];

        lastLabel = newLabel;
        [self addGestures];
    }
}

-(void)changeDraggedTagsFrom:(NSString *)oldLabel to:(NSString *)newLabel {
    NSArray *tags = [_dropOverlayView subviews];

    if( tags.count > 0 ) {
        for (TagView *tagView in tags) {
            if([tagView.text isEqualToString:oldLabel]) {
                tagView.text = newLabel;
                [tagView setNeedsDisplay];
            }
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length >= MAX_LENGTH && range.length == 0) {
        return NO; // return NO to not change text
    } else {
        return YES;
    }
}

#pragma mark - OBOvumSource

-(OBOvum *) createOvumFromView:(UIView*)sourceView
{
    NSLog(@"source %@ createOvumFromView", sourceView);
    OBOvum *ovum = [[OBOvum alloc] init];
    ovum.dataObject = sourceView.copy;
    return ovum;
}

- (void)ovumDragWillBegin:(OBOvum *)ovum {
    NSLog(@"Ovum<0x%x> %@ ovumDragWillBegin", (int)ovum, ovum.dataObject);
}

- (void)ovumDragEnded:(OBOvum *)ovum {
    NSLog(@"Ovum<0x%x> %@ ovumDragEnded", (int)ovum, ovum.dataObject);
}

-(UIView *) createDragRepresentationOfSourceView:(UIView *)sourceView inWindow:(UIWindow*)window
{

    NSLog(@"source %@ createDragRepresentationOfSourceView", sourceView);

    TagView *tagView = (TagView *)sourceView;

    CGRect frame = [sourceView convertRect:sourceView.bounds toView:sourceView.window];
    frame = [window convertRect:frame fromWindow:sourceView.window];

    TagView *dragView = [[TagView alloc] initWithFrame:frame];
    dragView.colorHightlighted = tagView.colorHightlighted;
    dragView.color = tagView.color;
    dragView.text = tagView.text;
    dragView.tag = tagView.tag;

    return dragView;
}


-(void) dragViewWillAppear:(UIView *)dragView inWindow:(UIWindow*)window atLocation:(CGPoint)location
{
    NSLog(@"DragViewWillAppear %@", dragView);
}

#pragma mark - OBDropZone

-(OBDropAction) ovumEntered:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
    NSLog(@"Ovum<0x%x> %@ Entered", (int)ovum, ovum.dataObject);

    return OBDropActionCopy;
}

-(void) ovumExited:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
}


-(OBDropAction) ovumMoved:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
    NSLog(@"Ovum<0x%x> %@ Moved", (int)ovum, ovum.dataObject);

    return OBDropActionCopy;
}



-(void) ovumDropped:(OBOvum*)ovum inView:(UIView*)view atLocation:(CGPoint)location
{
    NSLog(@"Ovum<0x%x> %@ Dropped", (int)ovum, ovum.dataObject);

    TagView *tagView = ovum.dataObject;

    tagView.center = location;

    TagView *copy = tagView.copy;

    [copy enablePanGesture];

    [_dropOverlayView addSubview:copy];
    [imageViewLabels addObject:copy];
}


@end
