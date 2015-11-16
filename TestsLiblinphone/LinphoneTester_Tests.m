//
//  LinphoneTester_Tests.m
//  LinphoneTester Tests
//
//  Created by guillaume on 10/09/2014.
//
//

#import <XCTest/XCTest.h>
#include "linphone/linphonecore.h"
#include "linphone/liblinphone_tester.h"
#import "NSObject+DTRuntime.h"
#import "Utils.h"

@interface LinphoneTester_Tests : XCTestCase
@property(retain, nonatomic) NSString *bundlePath;
@property(retain, nonatomic) NSString *documentPath;
@end

@implementation LinphoneTester_Tests

+ (NSArray *)skippedSuites {
	NSArray *skipped_suites = @[ @"Flexisip" ];
	return skipped_suites;
}

+ (NSString *)safetyTestString:(NSString *)testString {
	NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
	return [[testString componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@"_"];
}

+ (void)initialize {

	static char *bundle = NULL;
	static char *documents = NULL;
	bc_tester_init((void (*)(int, const char *fm, va_list))linphone_iphone_log_handler, ORTP_MESSAGE, ORTP_ERROR);
	liblinphone_tester_add_suites();

	NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = [paths objectAtIndex:0];
	bundle = ms_strdup([bundlePath UTF8String]);
	documents = ms_strdup([documentPath UTF8String]);

	LOGI(@"Bundle path: %@", bundlePath);
	LOGI(@"Document path: %@", documentPath);

	bc_tester_set_resource_dir_prefix(bundle);
	bc_tester_set_writable_dir_prefix(documents);

	liblinphone_tester_keep_accounts(TRUE);
	int count = bc_tester_nb_suites();

	for (int i = 0; i < count; i++) {
		const char *suite = bc_tester_suite_name(i);

		int test_count = bc_tester_nb_tests(suite);
		for (int k = 0; k < test_count; k++) {
			const char *test = bc_tester_test_name(suite, k);
			NSString *sSuite = [NSString stringWithUTF8String:suite];
			NSString *sTest = [NSString stringWithUTF8String:test];

			if ([[LinphoneTester_Tests skippedSuites] containsObject:sSuite])
				continue;
			// prepend "test_" so that it gets found by introspection
			NSString *safesTest = [self safetyTestString:sTest];
			NSString *safesSuite = [self safetyTestString:sSuite];
			NSString *selectorName = [NSString stringWithFormat:@"test_%@__%@", safesSuite, safesTest];

			[LinphoneTester_Tests addInstanceMethodWithSelectorName:selectorName
															  block:^(LinphoneTester_Tests *myself) {
																[myself testForSuite:sSuite andTest:sTest];
															  }];
		}
	}
}

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testForSuite:(NSString *)suite andTest:(NSString *)test {
	LOGI(@"Launching test %@ from suite %@", test, suite);
	XCTAssertFalse(bc_tester_run_tests([suite UTF8String], [test UTF8String]), @"Suite '%@' / Test '%@' failed", suite,
				   test);
}

- (void)dealloc {
	liblinphone_tester_clear_accounts();
}

@end
