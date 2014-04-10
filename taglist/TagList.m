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

    tagNames = tagTexts;
    tagViews = [[NSMutableArray alloc] init];
    [self refreshUI];
}

- (BOOL)addTag:(NSString *)tagName {
    if ([tagNames containsObject:tagName] == NO ) {

        if (tagViews.count < _maxNumberOfLabels) {
            [tagNames addObject:tagName];
            [self refreshUI];
            return YES;
        }
        return NO;
    }
    return NO;
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
    if (tagViews.count > 0) {
        [tagViews removeAllObjects];
    }


    NSInteger rowCount = ceil(tagNames.count / (float) TagListMaxTagsInRow);
    CGFloat width = tagNames.count * TagListElementWidth + (tagNames.count - 1) * TagListElementSpacingX;
    CGFloat height = rowCount * TagListElementHeight + (rowCount - 1) * TagListElementSpacingY;

    //self.frame = CGRectMake(posX, posY, width, height);

    CGFloat x = 0;
    CGFloat y = 0;

    NSInteger index = 0;
    NSInteger rowIndex = 0;

    for (NSString *str in tagNames) {
        TagView *tagView = [[TagView alloc] initWithFrame:CGRectMake(x, y, TagListElementWidth, TagListElementHeight)];

        NSInteger randomNumber = arc4random() % 100;
        tagView.tag = randomNumber;

        [tagView setText:str];

        //add gestures to it!
        _gestureAddHandler(tagView);

        [self addSubview:tagView];
        [tagViews addObject:tagView];


        [tagView setColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]];


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
