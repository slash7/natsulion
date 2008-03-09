#import "NTLNAppController.h"
#import "NTLNPreferencesWindowController.h"
#import "NTLNAccount.h"
#import "NTLNConfiguration.h"
#import "NTLNNotification.h"
#import "TwitterStatusViewController.h"

@implementation NTLNAppController

+ (void) setupDefaults {
    NSString *userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" 
                                                                       ofType:@"plist"]; 
//    NSLog(@"UserDefaults path: %@", userDefaultsValuesPath);

    NSDictionary *userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath]; 
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict]; 
}

+ (void) initialize {
//    NSLog(@"%s", __PRETTY_FUNCTION__); 
    [NTLNAppController setupDefaults];
    [NSColor setIgnoresAlpha:FALSE];
}

- (void) dealloc {
    [_refreshTimer release];
    [_badge release];
    [super dealloc];
}

- (int) refreshInterval {
    return _refreshInterval;
}

- (void) resetTimer {
    if (_refreshTimer) {
        [_refreshTimer invalidate];
        [_refreshTimer release];
    }
}

- (void) stopTimer {
    [self resetTimer];
}

- (void) startTimer {
    [self resetTimer];
    
    if (_refreshInterval < 30) {
        return;
    }

    _refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:_refreshInterval
                                                      target:mainWindowController
                                                    selector:@selector(updateStatus)
                                                    userInfo:nil
                                                     repeats:YES] retain];
}

- (void) setRefreshInterval:(int)interval {
    _refreshInterval = interval;
    
    if ([[NTLNAccount instance] username]) {
        [self startTimer];
    }
}

- (void) awakeFromNib { 
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(messageChangedToRead:)
                                                 name:NTLN_NOTIFICATION_MESSAGE_STATUS_MARKED_AS_READ
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(messageAdded:)
                                                 name:NTLN_NOTIFICATION_NEW_MESSAGE_ADDED
                                               object:nil];
    
    _badge = [[CTBadge alloc] init];
}

- (IBAction) showPreferencesSheet:(id)sender {
    [[NSApplication sharedApplication] beginSheet:[preferencesWindowController window]
                                   modalForWindow:[mainWindowController window]
                                    modalDelegate:self
                                   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
                                      contextInfo:nil];
}

- (IBAction) closePreferencesSheet:(id)sender {
    [[NSApplication sharedApplication] endSheet:[preferencesWindowController window] returnCode:0];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo {
    [[preferencesWindowController window] orderOut:self];
}

#pragma mark NSApplicatoin delegate methods
- (BOOL)applicationOpenUntitledFile:(NSApplication *)theApplication {
    //    NSLog(@"%s", __PRETTY_FUNCTION__);    
    [mainWindowController showWindowToFront];
    return TRUE;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    NSLog(@"%s", __PRETTY_FUNCTION__);    
    
    [mainWindowController setFrameAutosaveName:@"MainWindow"];
    
    [self bind:@"refreshInterval"
      toObject:[NSUserDefaultsController sharedUserDefaultsController] 
   withKeyPath:@"values.refreshIntervalSeconds"
       options:nil];
    
    [welcomeWindowController setWelcomeWindowControllerCallback:self];
    
    NSString *username = [[NTLNAccount instance] username];
    if (!username) {
        // first time
        [mainWindowController close];
      	[NSBundle loadNibNamed:@"Welcome" owner:welcomeWindowController];
        [welcomeWindowController showWindow:nil];
    } else {
        [mainWindowController showWindow:nil];
        if ([[NTLNAccount instance] password]) {
            [_refreshTimer fire];
        }
        [mainWindowController updateReplies];
    }
}


#pragma mark WelcomeWindowCallback methods
- (void) finishedToSetup {
    [welcomeWindowController close];
    [mainWindowController showWindow:nil];
    [self startTimer];
    [_refreshTimer fire];
}

#pragma mark Notification methods
- (void) writeNumberOfUnread {
    if (_numberOfUnreadMessage == 0) {
        [NSApp setApplicationIconImage:nil];
    } else {
        [_badge badgeApplicationDockIconWithValue:_numberOfUnreadMessage insetX:3 y:0];
    }
}

- (void) messageAdded:(NSNotification*)notification {
    NSArray *array = [notification object];
    for (int i = 0; i < [array count]; i++) {
        NTLNMessage *m = [(TwitterStatusViewController*)[array objectAtIndex:i] message];
        if ([m status] != NTLN_MESSAGE_STATUS_READ
            && ([m replyType] == MESSAGE_REPLY_TYPE_REPLY || [m replyType] == MESSAGE_REPLY_TYPE_REPLY_PROBABLE)) {
            _numberOfUnreadMessage++;
        }
    }
    [self writeNumberOfUnread];
}

- (void) messageChangedToRead:(NSNotification*)notification {
    NTLNMessage *m = [(TwitterStatusViewController*)[notification object] message];
    if (m == nil) {
        _numberOfUnreadMessage = 0;
    } else if ([m replyType] == MESSAGE_REPLY_TYPE_REPLY || [m replyType] == MESSAGE_REPLY_TYPE_REPLY_PROBABLE) {
        _numberOfUnreadMessage--;
    } else {
        return;
    }
    [self writeNumberOfUnread];
}
@end
