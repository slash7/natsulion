#import "Wassr.h"
#import "NTLNConfiguration.h"
#import "NTLNXMLHTTPEncoder.h"

@implementation WassrTimelineCallbackHandler

- (void) responseArrived:(NSData*)response statusCode:(int)code {
    [_callback twitterStopTask];

    NSString *responseStr = [NSString stringWithCString:[response bytes] encoding:NSUTF8StringEncoding];
    
//    NSLog(@"responseArrived:%@", responseStr);
    
    NSXMLDocument *document = nil;
    
    if (responseStr) {
        document = [[[NSXMLDocument alloc] initWithXMLString:responseStr options:0 error:NULL] autorelease];
    }

//#define DEBUG 1
#ifdef DEBUG
    switch ((int) ((float) rand() / RAND_MAX * 10)) {
        case 0:
        case 1:
        case 2:
            code = 200;
            break;
        case 3:
            code = 400;
            break;
        case 4:
            code = 401;
            break;
        case 5:
            code = 500;
            break;
        case 6:
            code = 501;
            break;
        case 7:
            code = 502;
            break;
        case 8:
            code = 503;
            break;
        default:
            code = 404;
            break;
    }
#endif
    
    if (!document || code >= 400) {
        NSLog(@"status code: %d - response:%@", code, responseStr);        
        switch (code) {
            case 400:
                [_callback failedToGetTimeline:[NTLNErrorInfo infoWithType:NTLN_ERROR_TYPE_HIT_API_LIMIT
                                                           originalMessage:[self appendCode:code 
                                                                                         to:NSLocalizedString(@"Exceeded the API rate limit", nil)]]];
                break;
            case 401:
                [_callback failedToGetTimeline:[NTLNErrorInfo infoWithType:NTLN_ERROR_TYPE_NOT_AUTHORIZED
                                                           originalMessage:[self appendCode:code
                                                                                         to:NSLocalizedString(@"Not Authorized", nil)]]];
                break;
            case 500:
            case 502:
            case 503:
                [_callback failedToGetTimeline:[NTLNErrorInfo infoWithType:NTLN_ERROR_TYPE_SERVER_ERROR
                                                           originalMessage:[self appendCode:code
                                                                                         to:NSLocalizedString(@"Twitter Server Error", nil)]]];
                break;
            default:
                [_callback failedToGetTimeline:[NTLNErrorInfo infoWithType:NTLN_ERROR_TYPE_OTHER 
                                                           originalMessage:[self appendCode:code
                                                                                         to:NSLocalizedString(@"Unknown Error", nil)]]];
                break;
        }
        return;
    }
    
    NSArray *statuses = [document nodesForXPath:@"/statuses/status" error:NULL];
    if ([statuses count] == 0) {
        NSLog(@"status code: %d - response:%@", code, responseStr);
        [_callback failedToGetTimeline:[NTLNErrorInfo infoWithType:NTLN_ERROR_TYPE_OTHER 
                                                   originalMessage:[self appendCode:code
                                                                                 to:NSLocalizedString(@"No message received", nil)]]];
    }
    
    for (NSXMLNode *status in statuses) {
        NTLNMessage *backStatus = [[[NTLNMessage alloc] init] autorelease];
		NSString *epoch = [self stringValueFromNSXMLNode:status byXPath:@"epoch/text()"];
		NSString *user_login_id = [self stringValueFromNSXMLNode:status byXPath:@"user_login_id/text()"];
		NSString *rid = [self stringValueFromNSXMLNode:status byXPath:@"rid/text()"];
        NSString *iconUrl = [self stringValueFromNSXMLNode:status byXPath:@"user/profile_image_url/text()"];

        [backStatus setStatusId:rid];
        [backStatus setName:user_login_id];
        [backStatus setScreenName:[[NTLNXMLHTTPEncoder encoder] decodeXML:[self stringValueFromNSXMLNode:status byXPath:@"user/screen_name/text()"]]];
        [backStatus setText:[[NTLNXMLHTTPEncoder encoder] decodeXML:[self stringValueFromNSXMLNode:status byXPath:@"text/text()"]]];
        [backStatus setText:[self decodeHeart:[backStatus text]]];
		
		NSString *reply_user_login_id = [self stringValueFromNSXMLNode:status byXPath:@"reply_user_login_id/text()"];
		if (reply_user_login_id && [reply_user_login_id length] > 0)
		{
			NSString *rt = @"@";
			rt = [rt stringByAppendingString:reply_user_login_id];

			NSRange r = [[backStatus text] rangeOfString:rt];
			if (r.length == 0)
			{
				rt = [rt stringByAppendingString:@" "];
				rt = [rt stringByAppendingString:[backStatus text]];
				[backStatus setText:rt];
			}
		}
		
		[backStatus setTimestamp:[NSDate dateWithTimeIntervalSince1970:[epoch intValue]]];
       
        [backStatus finishedToSetProperties];
        [_callback twitterStartTask];
        [_parent pushIconWaiter:backStatus forUrl:iconUrl];
		
//		NSLog(@"rid: %@ user_login_id: %@", rid, user_login_id);
	}
}

@end

@implementation WassrImpl

////////////////////////////////////////////////////////////////////

#pragma mark public methods
- (void) friendTimelineWithUsername:(NSString*)username password:(NSString*)password usePost:(BOOL)post {
    
    if (_connectionForFriendTimeline && ![_connectionForFriendTimeline isFinished]) {
        NSLog(@"connection for friend timeline is running.");
        return;
    }
    
    TwitterTimelineCallbackHandler *handler = [[TwitterTimelineCallbackHandler alloc] initWithCallback:_callback parent:self];

	NSString *url = @"http://api.wassr.jp/statuses/friends_timeline.xml";
    [_connectionForFriendTimeline release];
    _connectionForFriendTimeline = [[NTLNAsyncUrlConnection alloc] initWithUrl:url
                                                                  username:username
                                                                  password:password
                                                                   usePost:post
                                                                  callback:handler];
	if (!_connectionForFriendTimeline) {
        NSLog(@"failed to get connection.");
        return;
    }

    [_callback twitterStartTask];
}

- (void) repliesWithUsername:(NSString*)username password:(NSString*)password usePost:(BOOL)post {
	// not implemented
}

- (void) sentMessagesWithUsername:(NSString*)username password:(NSString*)password usePost:(BOOL)post {
	// not implemented
}

- (void) sendMessage:(NSString*)message username:(NSString*)username password:(NSString*)password {

    if (_connectionForPost && ![_connectionForPost isFinished]) {
        NSLog(@"connection for post is running.");
        return;
    }
    
    NSString *requestStr =  [@"status=" stringByAppendingString:[[NTLNXMLHTTPEncoder encoder] encodeHTTP:message]];
    requestStr = [requestStr stringByAppendingString:@"&source=natsulion"];
    
    TwitterPostCallbackHandler *handler = [[TwitterPostCallbackHandler alloc] initWithPostCallback:_callback];
    [_connectionForPost release];
    _connectionForPost = [[NTLNAsyncUrlConnection alloc] initPostConnectionWithUrl:@"http://api.wassr.jp/statuses/update.json"
                                                                        bodyString:requestStr 
                                                                          username:username
                                                                          password:password
                                                                          callback:handler];
    
    //    NSLog(@"sent data [%@]", requestStr);
    
    if (!_connectionForPost) {
        [_callback failedToPost:@"Posting a message failure. unable to get connection."];
        return;
    }
    
    [_callback twitterStartTask];
}

- (void) createFavorite:(NSString*)statusId username:(NSString*)username password:(NSString*)password {
    
    if (_connectionForFavorite && ![_connectionForFavorite isFinished]) {
        NSLog(@"connection for favorite is running.");
        return;
    }
    
    NSMutableString *urlStr = [[[NSMutableString alloc] init] autorelease];
    [urlStr appendString:@"http://api.wassr.jp/favorites/create/"];
    [urlStr appendString:statusId];
    [urlStr appendString:@".json"];
    
    TwitterFavoriteCallbackHandler *handler = [[TwitterFavoriteCallbackHandler alloc] initWithStatusId:statusId callback:_callback];
    [_connectionForFavorite release];
    _connectionForFavorite = [[NTLNAsyncUrlConnection alloc] initWithUrl:urlStr
                                                                username:username
                                                                password:password
                                                                 usePost:TRUE
                                                                callback:handler];
    
//    NSLog(@"sent data [%@]", urlStr);
    
    if (!_connectionForFavorite) {
        [_callback failedToChangeFavorite:statusId errorInfo:[NTLNErrorInfo infoWithType:NTLN_ERROR_TYPE_OTHER
                                                                         originalMessage:NSLocalizedString(@"Sending a message failure. unable to get connection.", nil)]];
        return;
    }
    
    [_callback twitterStartTask];
}

@end

///////////////////////////////////////////

@implementation WassrCheck

- (void) checkAuthentication:(NSString*)username password:(NSString*)password callback:(NSObject<TwitterCheckCallback>*)callback {

    _callback = callback;
    [_callback retain];
    
    _connection = [[NTLNAsyncUrlConnection alloc] initWithUrl:@"http://api.wassr.jp/statuses/friends_timeline.rss" 
                                                 username:username
                                                 password:password
                                                  usePost:FALSE
                                                 callback:self];
    if (!_connection) {
        NSLog(@"failed to get connection.");
        [_callback finishedToCheck:NTLN_TWITTERCHECK_FAILURE];
    }
}

@end
