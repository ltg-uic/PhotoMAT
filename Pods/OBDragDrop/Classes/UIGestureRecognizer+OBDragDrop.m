//
//  UIGestureRecognizer+OBDragDrop.m
//  OBDragDropTest
//
//  Created by Zai Chang on 11/15/12.
//  Copyright (c) 2012 Oblong Industries. All rights reserved.
//

#import "UIGestureRecognizer+OBDragDrop.h"
#import <objc/runtime.h>


static NSString *kOBGestureRecognizerOvumKey = @"OBGestureRecognizerOvum";
static NSString *kOBGestureRecognizerOvumSourceKey = @"OBGestureRecognizerOvumSource";


@implementation UIGestureRecognizer (OBDragDrop)

-(OBOvum *) ovum
{
  OBOvum *ovum = (OBOvum *) objc_getAssociatedObject(self, CFBridgingRetain(kOBGestureRecognizerOvumKey));
  return ovum;
}


-(void) setOvum:(OBOvum *)ovum
{
  objc_setAssociatedObject (self,
                            CFBridgingRetain(kOBGestureRecognizerOvumKey),
                            ovum,
                            OBJC_ASSOCIATION_RETAIN
                            );
}


-(id<OBOvumSource>) ovumSource
{
  id<OBOvumSource> handler = (id<OBOvumSource>) objc_getAssociatedObject(self, CFBridgingRetain(kOBGestureRecognizerOvumSourceKey));
  return handler;
}


-(void) setOvumSource:(id<OBOvumSource>)ovumSource
{
  objc_setAssociatedObject (self,
                            CFBridgingRetain(kOBGestureRecognizerOvumSourceKey),
                            ovumSource,
                            OBJC_ASSOCIATION_ASSIGN
                            );
}

@end
