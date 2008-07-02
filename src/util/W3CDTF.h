/*
 The revised BSD license
 
 Copyright (c) 2008 Lyo Kato <lyo.kato at gmail dot com>
 All rights reserved.
 
 This file is part of Atompub
 http://coderepos.org/share/browser/lang/objective-c/Atompub/trunk/Classes/W3CDTF.h?rev=14461
 */

#import <Foundation/Foundation.h>

@interface W3CDTF : NSObject {
}
+ (NSDate *)dateFromString:(NSString *)formattedDate;
+ (NSString *)stringFromDate:(NSDate *)date;
@end
