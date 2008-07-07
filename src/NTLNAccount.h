#import <Cocoa/Cocoa.h>
#import "EMKeychainProxy.h"

@class NTLNAccount;

@interface NTLNAccountManager : NSObject
{
	NTLNAccount *twitterAccount;
	NTLNAccount *wassrAccount;
}

+ (id) instance;

@property (readonly) NTLNAccount *twitterAccount, *wassrAccount;

@end

@interface NTLNAccount : NSObject {
    NSString *_username;
    NSString *_password;
	NSString *prefName;
	EMInternetKeychainItem *keychainItem;
}

- (id) initWithPrefName:(NSString*)prefname keychainServerName:(NSString *)serverName;
- (NSString*) username;
- (NSString*) password;
- (BOOL) addOrUpdateKeyChainWithPassword:(NSString*)password;
- (BOOL) isValid;
@end


