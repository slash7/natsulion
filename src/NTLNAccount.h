#import <Cocoa/Cocoa.h>

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
}

- (id) initWithPrefName:(NSString*)prefname;
- (NSString*) username;
- (NSString*) password;
- (BOOL) addOrUpdateKeyChainWithPassword:(NSString*)password;
- (BOOL) isValid;
@end


