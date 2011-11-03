#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SpringBoard/SpringBoard-Class.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBAppSwitcherController.h>
#import <SpringBoard/SBAppSwitcherBarView.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBNowPlayingBar.h>
#import <SpringBoard/SBIconView.h>
#import <SpringBoard/SBIcon-SBApplicationIcon.h>
#import "libactivator/libactivator.h"


#define PreferencesChangedNotification "com.mathieubolard.killbackground.prefs"
#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/com.mathieubolard.killbackgroundpreferences.plist"]

static NSDictionary *preferences = nil;

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[preferences release];
	preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
}


@interface KillBackground : NSObject<LAListener> {}
+ (int) killBackgroundAppsFromSwitcher:(SBAppSwitcherController *)switcher;
@end

@interface SBAppSwitcherController (Kill)
- (void) killApps;
- (UIButton *)killButtonInFrame:(CGSize)frame isLeft:(BOOL)isLeft;
- (void)showBigButtonsInView:(UIView *)view;
- (void) clearSwitcherBar:(SBAppSwitcherBarView *)barView;
@end

@interface SBAppIconQuitButton : UIButton
@property(retain, nonatomic) SBApplicationIcon *appIcon;
@end

@implementation SBAppIconQuitButton
@synthesize appIcon;
@end;


%hook SBAppSwitcherController

- (void) viewWillAppear {
	%orig;
	
	//Get the SwitcherBarView
	SBAppSwitcherBarView *barView = MSHookIvar<SBAppSwitcherBarView *>(self, "_bottomBar");
		
	// Clear the old button(s)
	[self clearSwitcherBar:barView];
    
	BOOL alwaysVisible = [[preferences objectForKey:@"AlwaysVisible"] boolValue];
    
	if (alwaysVisible) {
		BOOL bigButtons = [[preferences objectForKey:@"BigButtons"] boolValue];
		// Add button
        if (bigButtons) {
            [self showBigButtonsInView:barView];
        }else {
            BOOL isLeft = [[preferences objectForKey:@"Left"] boolValue];
            CGSize barSize = barView.frame.size;
            UIButton *btn = [self killButtonInFrame:barSize isLeft:isLeft];
            [barView addSubview:btn];
        }
	}
	
}

- (void)_beginEditing {
	%orig;
    
    BOOL alwaysVisible = [[preferences objectForKey:@"AlwaysVisible"] boolValue];
    
	if (!alwaysVisible) {
        SBAppSwitcherBarView *barView = MSHookIvar<SBAppSwitcherBarView *>(self, "_bottomBar");
        
		BOOL bigButtons = [[preferences objectForKey:@"BigButtons"] boolValue];
		// Add button
        if (bigButtons) {
            [self showBigButtonsInView:barView];
        }else {
            BOOL isLeft = [[preferences objectForKey:@"Left"] boolValue];
            CGSize barSize = barView.frame.size;
            UIButton *btn = [self killButtonInFrame:barSize isLeft:isLeft];
            [barView addSubview:btn];
        }
	}
}

- (void)_stopEditing {
	%orig;
    
    BOOL alwaysVisible = [[preferences objectForKey:@"AlwaysVisible"] boolValue];
    
	if (!alwaysVisible) {
        SBAppSwitcherBarView *barView = MSHookIvar<SBAppSwitcherBarView *>(self, "_bottomBar");
		[self clearSwitcherBar:barView];
	}
}

%new(v@:@@)
- (void) killApps {
    
	[KillBackground killBackgroundAppsFromSwitcher:(SBAppSwitcherController *)self];

    BOOL autoHide = [[preferences objectForKey:@"AutoHide"] boolValue];
    if (autoHide) {
        SBUIController *uiCont = [%c(SBUIController) sharedInstance];
        if ([uiCont respondsToSelector:@selector(dismissSwitcherAnimated:)]) {
        	[uiCont dismissSwitcherAnimated:YES];
    	}else {
    		[uiCont _dismissSwitcher:0.4];
    	}
    }
}
%new(v@:@@)
- (UIButton *)killButtonInFrame:(CGSize)frame isLeft:(BOOL)isLeft {
	// Create button
	UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
	btn.autoresizingMask = isLeft ? (UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin) : (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin);
	[btn setImage:[UIImage imageWithContentsOfFile:@"/System/Library/CoreServices/SpringBoard.app/Kill-Badge.png"] forState:UIControlStateNormal];
    btn.frame = isLeft ? CGRectMake(0.0, frame.height-31.0, 29.0, 31.0) : CGRectMake(frame.width-29.0, frame.height-31.0, 29.0, 31.0);
	[btn addTarget:self action:@selector(killApps) forControlEvents:UIControlEventTouchUpInside];
	return btn;
}
%new(v@:@@)
- (void)showBigButtonsInView:(UIView *)view {
    
    CGSize frame = view.frame.size;
    UIButton *leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    leftBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [leftBtn setImage:[UIImage imageWithContentsOfFile:@"/System/Library/CoreServices/SpringBoard.app/Kill-Left.png"] forState:UIControlStateNormal];
    leftBtn.frame = CGRectMake(0.0, frame.height-40.0, 40.0, 40.0);
	[leftBtn addTarget:self action:@selector(killApps) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:leftBtn];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [rightBtn setImage:[UIImage imageWithContentsOfFile:@"/System/Library/CoreServices/SpringBoard.app/Kill-Right.png"] forState:UIControlStateNormal];
    rightBtn.frame = CGRectMake(frame.width-40.0, frame.height-40.0, 40.0, 40.0);
	[rightBtn addTarget:self action:@selector(killApps) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:rightBtn];
}
%new(v@:@@)
- (void) clearSwitcherBar:(SBAppSwitcherBarView *)barView {
	for (id subview in [barView subviews]) {
        if ([subview isKindOfClass:[UIButton class]]) {
    		[subview removeFromSuperview];
    	}
    }
}

%end



@implementation KillBackground

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	NSLog(@"Event : %@",[event description]);
	if ([event.name rangeOfString:@"libactivator.statusbar."].location != NSNotFound
	&& [event.mode isEqualToString:@"application"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"We can't kill apps" message:@"In app statusbar activations can prevent KillBackground to operate properly." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    	[alert show];
    	[alert release];
    	return;
	}
	
	SBUIController *uiCont = [%c(SBUIController) sharedInstance];
	BOOL isShowing = [uiCont isSwitcherShowing];
	[uiCont _toggleSwitcher];

    SBAppSwitcherController *switchCont = [%c(SBAppSwitcherController) sharedInstance];
	int count = [KillBackground killBackgroundAppsFromSwitcher:switchCont];
	NSString *message = nil;
	if (!isShowing) {
		if ([uiCont respondsToSelector:@selector(dismissSwitcherAnimated:)]) {
        	[uiCont dismissSwitcherAnimated:NO];
    	}else {
    		[uiCont _dismissSwitcher:0.0];
    	}
    	if ([event.mode isEqualToString:@"springboard"] && [uiCont respondsToSelector:@selector(createFakeSpringBoardStatusBar)]) {
        	[uiCont createFakeSpringBoardStatusBar];
        	[uiCont setFakeSpringBoardStatusBarVisible:YES];
    	}
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Killed %i apps",count] message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

+ (int) killBackgroundAppsFromSwitcher:(SBAppSwitcherController *)switcher {

	if (!switcher) {
		switcher = [%c(SBAppSwitcherController) sharedInstance];
	}
	
	BOOL killMusic = [[preferences objectForKey:@"KillMusic"] boolValue];
	BOOL isPlaying = [(SpringBoard *)[UIApplication sharedApplication] isNowPlayingAppPlaying];
	
	float isFirmware = [[[UIDevice currentDevice] systemVersion] floatValue];
	SBNowPlayingBar *playingBar = (isFirmware > 4.1) ? MSHookIvar<SBNowPlayingBar *>(switcher, "_nowPlayingBar") : MSHookIvar<SBNowPlayingBar *>(switcher, "_nowPlaying");
    NSString *playingID = @"";
    if (playingBar) {
        SBApplication *nowPlayingApp = MSHookIvar<SBApplication *>(playingBar, "_nowPlayingApp");
        playingID = [nowPlayingApp displayIdentifier];
    }
	
	int count = 0;
    
	
	if (isFirmware >= 5.0) {
	
		// iOS 5 kill all Apps
		NSArray *icons = [switcher _applicationIconsExceptTopApp];
		count = [icons count];
                    
    	for (SBIconView *icon in icons) {

    		if (!killMusic && isPlaying) {
    			NSString *testID = [[icon.icon application] displayIdentifier];
    			if ((testID != nil) && [testID isEqualToString:playingID]) {
    				count--;
    				continue;
    			}
    		}
        	[switcher iconCloseBoxTapped:icon];
    	}
	
	}else {
	
		// iOS 4 kill all Apps
		SBAppSwitcherBarView *barView = MSHookIvar<SBAppSwitcherBarView *>(switcher, "_bottomBar");
		NSArray *icons = [MSHookIvar<NSArray *>(barView, "_appIcons") copy];
		count = [icons count];
		
    	for (SBApplicationIcon *icon in icons) {
			
            if (!killMusic && isPlaying) {
                NSString *testID = [[icon application] displayIdentifier];
                if ((testID != nil) && [testID isEqualToString:playingID]) {
                    count--;
                    continue;
                }	
            }
        	if (isFirmware >= 4.1f) {
            	[switcher iconCloseBoxTapped:icon];
        	} else {
            	SBAppIconQuitButton *quitBtn = [SBAppIconQuitButton buttonWithType:UIButtonTypeCustom];
            	quitBtn.appIcon = icon;
            	[switcher _quitButtonHit:quitBtn];
        	}
    	}

    	[icons release];
	}
	return count;
}

+ (void)load
{
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	[[%c(LAActivator) sharedInstance] registerListener:[self new] forName:@"com.mathieubolard.killbackground"];
	[p release];
}

@end


__attribute__((constructor)) static void killbackground_init() {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
    
	// Load manually because it's not linked with libactivator
	[KillBackground load];
    
    preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
    
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
    
	[pool release];
    
}