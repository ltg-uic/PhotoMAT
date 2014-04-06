//
//  NSString+EUCStringExtensions.m
//  TrapEase
//
//  Created by Aijaz Ansari on 4/6/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "NSString+EUCStringExtensions.h"

@implementation NSString (EUCStringExtensions)

// from http://stackoverflow.com/a/3436193/772526
// Note: this has to be a class method because it should return YES when the target string is nil
+ (BOOL)isStringEmpty:(NSString *)string {
    if([string length] == 0) { //string is empty or nil
        return YES;
    }
    
    if(![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

@end
