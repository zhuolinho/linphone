//
//  WizardTester.m
//  linphone
//
//  Created by Guillaume on 17/01/2015.
//
//

#import "AssistantTester.h"
#import <KIF/KIF.h>

@implementation AssistantTester

- (void)beforeEach {
	[super beforeEach];
	[UIView setAnimationsEnabled:false];

	[tester tapViewWithAccessibilityLabel:@"Settings"];
	[tester tapViewWithAccessibilityLabel:@"Run assistant"];
	[tester waitForTimeInterval:0.5];
	if ([tester tryFindingViewWithAccessibilityLabel:@"Launch Wizard" error:nil]) {
		[tester tapViewWithAccessibilityLabel:@"Launch Wizard"];
		[tester waitForTimeInterval:0.5];
	}
}

- (void)afterEach {
	[super afterEach];
	[tester tapViewWithAccessibilityLabel:@"Dialer"];
}

#pragma mark - Utilities

- (void)_linphoneLogin:(NSString *)username withPW:(NSString *)pw {
	[tester tapViewWithAccessibilityLabel:@"Start"];
	[tester tapViewWithAccessibilityLabel:@"Sign in linphone.org account"];

	[tester enterText:username intoViewWithAccessibilityLabel:@"Username"];
	[tester enterText:pw intoViewWithAccessibilityLabel:@"Password"];

	[tester tapViewWithAccessibilityLabel:@"Sign in"];
}

- (void)_externalLoginWithProtocol:(NSString *)protocol {
	[tester tapViewWithAccessibilityLabel:@"Start"];
	[tester tapViewWithAccessibilityLabel:@"Sign in SIP account"];

	[tester enterText:[self me] intoViewWithAccessibilityLabel:@"Username"];
	[tester enterText:[self me] intoViewWithAccessibilityLabel:@"Password"];
	[tester enterText:[self accountDomain] intoViewWithAccessibilityLabel:@"Domain"];
	[tester tapViewWithAccessibilityLabel:protocol];

	[tester tapViewWithAccessibilityLabel:@"Sign in"];
	[self waitForRegistration];
}

#pragma mark - Tests

- (void)testAccountCreation {
	NSString *username = [NSString stringWithFormat:@"%@-%.2f", [self getUUID], [[NSDate date] timeIntervalSince1970]];
	[tester tapViewWithAccessibilityLabel:@"Start"];
	[tester tapViewWithAccessibilityLabel:@"Create linphone.org account" traits:UIAccessibilityTraitButton];

	[tester enterText:username intoViewWithAccessibilityLabel:@"Username"];
	[tester enterText:username intoViewWithAccessibilityLabel:@"Password "];
	[tester enterText:username intoViewWithAccessibilityLabel:@"Password again"];
	[tester enterText:@"testios@.dev.null" intoViewWithAccessibilityLabel:@"Email"];

	[tester tapViewWithAccessibilityLabel:@"Register" traits:UIAccessibilityTraitButton];

	[tester waitForViewWithAccessibilityLabel:@"Check validation" traits:UIAccessibilityTraitButton];
	[tester tapViewWithAccessibilityLabel:@"Check validation"];

	[tester waitForViewWithAccessibilityLabel:@"Account validation issue"];
	[tester tapViewWithAccessibilityLabel:@"Continue"];
	[tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)testExternalLoginWithTCP {
	[self _externalLoginWithProtocol:@"TCP"];
}

- (void)testExternalLoginWithTLS {
	[self _externalLoginWithProtocol:@"TLS"];
}

- (void)testExternalLoginWithUDP {
	[self _externalLoginWithProtocol:@"UDP"];
}

- (void)testLinphoneLogin {
	[self _linphoneLogin:@"testios" withPW:@"testtest"];

	// check the registration state
	[self waitForRegistration];
}

- (void)testLinphoneLoginWithBadPassword {
	[self _linphoneLogin:@"testios" withPW:@"badPass"];

	[self setInvalidAccountSet:true];

	UIView *alertViewText =
		[tester waitForViewWithAccessibilityLabel:@"Registration failure" traits:UIAccessibilityTraitStaticText];
	if (alertViewText) {
		UIView *reason = [tester waitForViewWithAccessibilityLabel:@"Incorrect username or password."
															traits:UIAccessibilityTraitStaticText];
		if (reason == nil) {
			[tester fail];
		} else {
			[tester tapViewWithAccessibilityLabel:@"OK"];	 // alertview
			[tester tapViewWithAccessibilityLabel:@"Cancel"]; // cancel wizard
		}
	} else {
		[tester fail];
	}
}

- (void)testRemoteProvisioning {
	[tester tapViewWithAccessibilityLabel:@"Start"];
	[tester tapViewWithAccessibilityLabel:@"Remote provisioning"];
	[tester enterTextIntoCurrentFirstResponder:@"smtp.linphone.org/testios_xml"];
	[tester tapViewWithAccessibilityLabel:@"Fetch"];
	[self waitForRegistration];
}
@end
