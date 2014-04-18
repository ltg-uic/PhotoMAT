#import "TagList.h"
#import "TagView.h"



static const CGFloat TagListElementWidth = 151;
static const CGFloat TagListElementHeight = 30;
static const CGFloat TagListElementSpacingX = 2;
static const CGFloat TagListElementSpacingY = 2;
static const NSInteger TagListMaxTagsInRow = 2;
static const CGFloat TagListDefaultHighlightAlpha = 0.7f;

@interface TagList () {
    NSMutableArray *tagNames;
    NSMutableArray *tagViews;
    CGFloat posX;
    CGFloat posY;
    NSMutableDictionary *tagNamesToLabelIds;


}

@end

@implementation TagList

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        posX = frame.origin.x;
        posY = frame.origin.y;
    }

    return self;
}

//called when defined in interface builder
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    posX = self.frame.origin.x;
    posY = self.frame.origin.y;

    [self initTagData];

}

- (id)init {
    self = [self initWithFrame:CGRectMake(0, 0, 0, 0)];

    return self;
}

- (id)initWithX:(CGFloat)x withY:(CGFloat)y {
    self = [self initWithFrame:CGRectMake(x, y, 0, 0)];

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    posX = self.frame.origin.x;
    posY = self.frame.origin.y;
}

- (void)setPosX:(CGFloat)x andY:(CGFloat)y {
    posX = x;
    posY = y;
}

- (void)initTagListWithTagNames:(NSMutableArray *)tagTexts {
    if (_maxNumberOfLabels <= 0) {
        _maxNumberOfLabels = 2;
    }

    tagViews = [[NSMutableArray alloc] init];

    if( tagTexts != nil ) {
        tagNames = tagTexts;

    } else {
        tagNames = [[NSMutableArray alloc] init];
    }

    [self refreshUI];

}

- (void)initTagData {
    if (_maxNumberOfLabels <= 0) {
        _maxNumberOfLabels = 2;
    }

    tagViews = [[NSMutableArray alloc] init];


    tagNames = [[NSMutableArray alloc] init];



}


-(void) clearList {
    [tagNames removeAllObjects];

    for (TagView *tv in tagViews) {
        [tv removeFromSuperview];
    }
    [tagViews removeAllObjects];
}

-(BOOL)isDuplicateTag:(NSString *)tagName {
    if( [tagNames containsObject:tagName] ) {
         return YES;
    }
    return NO;
}


- (BOOL)addTag:(NSString *)tagName withLabelId:(NSInteger)labelId {

    if( tagNames == nil ) {
        tagNames = [[NSMutableArray alloc] init];
    }

    if ([self isDuplicateTag:tagName] == NO ) {

        if (tagViews.count < _maxNumberOfLabels) {
            [tagNames addObject:tagName];

            TagView *tagView = [[TagView alloc] initWithFrame:CGRectMake(0, 0, TagListElementWidth, TagListElementHeight)];

            NSInteger randomNumber = arc4random() % 100;
            tagView.labelId = labelId;
            tagView.tag = randomNumber;

            [tagView setText:tagName];

            //add gestures to it!
            _gestureAddHandler(tagView);

            [tagView setColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]];

            [tagViews addObject:tagView];






            [self refreshUI];
            return YES;
        }
        return NO;
    }
    return NO;
}

-(TagView *)getTagViewCopy: (NSString *)tagName {

    NSArray *tag = [tagViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"text == %@", tagName]];

    if( tag.count > 0 ) {
        return tag[0];
    }

    return nil;
}

- (int)indexOfTag:(NSString *)tagName {
    if (tagNames != nil && [tagNames containsObject:tagName]) {
        return [tagNames indexOfObject:tagName];
    }
    return -1;
}

- (BOOL)removeTag:(NSString *)tagName {
    if ([tagNames containsObject:tagName]) {
        [tagNames removeObject:tagName];
        [self refreshUI];
        return YES;
    }
    return NO;
}

- (void)changeTagNameFrom:(NSString *)oldLabel to:(NSString *)newLabel {
    int index = [tagNames indexOfObject:oldLabel];
    if (index >= 0) {
        [tagNames replaceObjectAtIndex:index withObject:newLabel];
        for (TagView *tv in tagViews) {
            if ([tv.text isEqualToString:oldLabel]) {
                tv.text = newLabel;
                [tv setNeedsDisplay];
            }
        }
    }
}

- (void)refreshUI {

    //self.backgroundColor = [UIColor orangeColor];
    for (TagView *tv in tagViews) {
        [tv removeFromSuperview];
    }
//    if (tagViews.count > 0) {
//        [tagViews removeAllObjects];
//    }


    NSInteger rowCount = ceil(tagNames.count / (float) TagListMaxTagsInRow);
    CGFloat width = tagNames.count * TagListElementWidth + (tagNames.count - 1) * TagListElementSpacingX;
    CGFloat height = rowCount * TagListElementHeight + (rowCount - 1) * TagListElementSpacingY;

    //self.frame = CGRectMake(posX, posY, width, height);

    CGFloat x = 0;
    CGFloat y = 0;

    NSInteger index = 0;
    NSInteger rowIndex = 0;

    for (TagView *tv in tagViews) {
        tv.frame = CGRectMake(x, y, TagListElementWidth, TagListElementHeight);



        [self addSubview:tv];


        ++index;
        ++rowIndex;
        x += TagListElementWidth + TagListElementSpacingX;
        if (rowIndex == TagListMaxTagsInRow) {
            x = 0;
            rowIndex = 0;
            y += TagListElementHeight + TagListElementSpacingY;
        }
    }
}

@end
