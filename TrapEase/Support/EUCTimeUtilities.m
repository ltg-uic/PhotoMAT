//
//  EUCTimeUtilities.m
//  PhotoMat
//
//  Created by Aijaz Ansari on 4/13/14.
//  Copyright (c) 2014 Euclid Software, LLC. All rights reserved.
//

#import "EUCTimeUtilities.h"

@implementation EUCTimeUtilities

+(NSString *)currentTimeInZulu {
    NSDate* datetime = [NSDate date];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:SS.SSS'Z'"];
    NSString* dateTimeInIsoFormatForZuluTimeZone = [dateFormatter stringFromDate:datetime];
    return dateTimeInIsoFormatForZuluTimeZone;
}
@end
