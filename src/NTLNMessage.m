#import "NTLNMessage.h"
#import "NTLNAccount.h"

@implementation NTLNMessage

@synthesize statusId, name, screenName, text, icon, timestamp, replyType, status, user;

- (void) dealloc {
    [statusId release];
    [name release];
    [screenName release];
    [text release];
    [icon release];
    [timestamp release];
    [super dealloc];
}

- (BOOL) isEqual:(id)anObject {
    if ([[self statusId] isEqual:[anObject statusId]]) {
        return TRUE;
    }
    return FALSE;
}

- (void) setStatus:(enum NTLNMessageStatus)value {
    status = value;
}

- (BOOL) isReplyToMe {
    if ([text hasPrefix:[@"@" stringByAppendingString:[[[NTLNAccountManager instance] twitterAccount] username]]]) {
        //        NSLog(@"reply");
        return TRUE;
    }
    //    NSLog(@"not reply");
    return FALSE;
}

- (BOOL) isProbablyReplyToMe {
    NSString *query = [@"@" stringByAppendingString:[[[NTLNAccountManager instance] twitterAccount] username]];
    NSRange range = [text rangeOfString:query];
    
    if (range.location != NSNotFound) {
        //        NSLog(@"probable reply");
        return TRUE;
    }
    //    NSLog(@"not reply");
    return FALSE;
}

- (BOOL) isMyUpdate {
    return [screenName isEqualToString:[[[NTLNAccountManager instance] twitterAccount] username]];
}

- (void) finishedToSetProperties {
    if ([self isMyUpdate]) {
        replyType = NTLN_MESSAGE_REPLY_TYPE_MYUPDATE;
    } else if ([self isReplyToMe]) {
        replyType = NTLN_MESSAGE_REPLY_TYPE_REPLY;
    } else if ([self isProbablyReplyToMe]) {
        replyType = NTLN_MESSAGE_REPLY_TYPE_REPLY_PROBABLE;
    } else {
        replyType = NTLN_MESSAGE_REPLY_TYPE_NORMAL;
    }
}

@end
