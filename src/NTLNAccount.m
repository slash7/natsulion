#import "NTLNAccount.h"
#import "NTLNPreferencesWindowController.h"

#define TWITTER_USER_ID_PREF_NAME		@"userId"
#define TWITTER_KEYCHAIN_SERVER_NAME	@"twitter.com"
#define WASSR_USER_ID_PREF_NAME			@"userIdWasser"
#define WASSR_KEYCHAIN_SERVER_NAME		@"wasser.jp"

static NTLNAccountManager *_instance;

@implementation NTLNAccountManager

@synthesize twitterAccount, wassrAccount;

+ (id) instance {
	@synchronized(self) {
        if(!_instance) {
            _instance = [[self alloc] init];
        }
    }
	return _instance;
}

+(id) allocWithZone:(NSZone*)zone
{
    @synchronized(self) {
        if(!_instance) {
            _instance = [super allocWithZone:zone];
        }
    }
    return _instance; 
}

-(id)init
{
	twitterAccount = [[NTLNAccount alloc] initWithPrefName:TWITTER_USER_ID_PREF_NAME 
										keychainServerName:TWITTER_KEYCHAIN_SERVER_NAME];
	
	wassrAccount = [[NTLNAccount alloc] initWithPrefName:WASSR_USER_ID_PREF_NAME 
									  keychainServerName:WASSR_KEYCHAIN_SERVER_NAME];
	return [super init];
}

-(void) dealloc {
	[twitterAccount release];
	[wassrAccount release];
	[super dealloc];
}

-(id)copyWithZone:(NSZone*)zone {
    return self;
}

-(id)retain {
    return self;
}

-(unsigned)retainCount {
    return UINT_MAX; // 
}

-(void)release {
}

-(id)autorelease {
    return self;
}

@end


@implementation NTLNAccount

- (id) initWithPrefName:(NSString*)prefn keychainServerName:(NSString *)serverName {
	prefName = prefn;
	[prefName retain];

	_username = [[NSUserDefaults standardUserDefaults] objectForKey:prefName];
	
	keychainItem = [[EMKeychainProxy sharedProxy] internetKeychainItemForServer:serverName 
																   withUsername:_username 
																		   path:nil
																		   port:80 
																	   protocol:kSecProtocolTypeHTTP];
	[keychainItem retain];
	return self;
}

- (void) dealloc {
	[keychainItem release];
    [_username release];
	[prefName release];
    [super dealloc];
}

- (NSString*) username {
    return _username;
}

- (NSString*) password {
    return [keychainItem password];
}

- (BOOL) addOrUpdateKeyChainWithPassword:(NSString*)password {
	[keychainItem username];
	[keychainItem password];
	return TRUE;
}

- (BOOL) isValid {
	return ([self password] != nil) ? TRUE : FALSE;
}

@end
