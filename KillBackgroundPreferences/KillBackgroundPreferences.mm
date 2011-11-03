#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

@interface KillBackgroundPreferencesListController: PSListController { }
@end

@implementation KillBackgroundPreferencesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"KillBackgroundPreferences" target:self] retain];
	}
	return _specifiers;
}

- (void) donate:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/pDWsMQ"]];
}
@end