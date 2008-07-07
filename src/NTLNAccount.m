#import "NTLNAccount.h"
#import "NTLNKeyChain.h"
#import "NTLNPreferencesWindowController.h"

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
	twitterAccount = [[NTLNAccount alloc] initWithPrefName:@"userId"];
	wassrAccount = [[NTLNAccount alloc] initWithPrefName:@"userIdWasser"];
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

- (id) initWithPrefName:(NSString*)prefn {
	prefName = prefn;
	[prefName retain];
	_username = [[NSUserDefaults standardUserDefaults] objectForKey:prefName];
    return self;
}

- (void) dealloc {
    [_username release];
	[prefName release];
    [super dealloc];
}

- (NSString*) username {
    return _username;
}

- (NSString*) password {
    return [[NTLNKeyChain keychain] getPasswordForUsername:[self username]];
}

- (BOOL) addOrUpdateKeyChainWithPassword:(NSString*)password {
    return [[NTLNKeyChain keychain] addOrUpdateWithUsername:[self username] password:password];
}

- (BOOL) isValid {
	return ([self password] != nil) ? TRUE : FALSE;
}



@end
