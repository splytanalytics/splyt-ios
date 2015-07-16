//
//  SplytTests.m
//  SplytTests
//
//  Created by Andrew Brown on 1/14/14.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

@import UIKit; // Splyt requires linking against UIKit
#import <XCTest/XCTest.h>
#import "Splyt.h"

@interface SplytTests : XCTestCase

@end

@implementation SplytTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInstrumentation
{
    // This would be the simplest case where we only set the customer id
    // [[Splyt Core] init:[SplytInitParams createWithCustomerId:@"splyt-bubblepop-test"] andThen:^(SplytError error) {
    //     NSLog(@"WoOt");
    // }];

    // But for a typical application, you will want to set some additional parameters, which can looks something like this
    SplytInitParams* initParams = [SplytInitParams createWithCustomerId:@"splyt-bubblepop-test" andInitBlock:^(SplytInitParams *init) {
        // (optional) allows NSLog to occur for debug & error info - only enable during development
        init.logEnabled = YES;

        // (optional) number of milliseconds before the init call (and other requests) will be timed out
        init.requestTimeout = 2500;

        // (optional) if we know anything about the device at startup, we can set it thusly
        // init.deviceInfo = [SplytEntityInfo createDeviceInfoWithInitBlock:^(SplytEntityInfo *device) {
        //     [device setProperty:@"testa" withValue:@"testb"];
        // }];

        // (optional) if we know anything about the user at startup, we can set it thusly
        // init.userInfo = [SplytEntityInfo createUserInfo:@"testUser" withInitBlock:^(SplytEntityInfo *user) {
        //     [user setProperty:@"testa" withValue:@"testb"];
        // }];

        // (avoid) this is intended for Splyt developers, don't use it
        // init.host = @"http://localhost";
    }];

    __block BOOL done = NO;

    [[Splyt Core] init:initParams andThen:^(SplytError error) {
        XCTAssertTrue(SplytError_Success == error, @"Initialization failed!  Instrumentation and Tuning may not work as expected.");

        // the session plugin makes it easy to mark the start of a new session
        [[[SplytPlugins Session] Transaction] begin];

        // like any transaction, a session can have additional properties
        // [[[SplytPlugins Session] TransactionWithInitBlock:^(SplytSessionTransaction *session) {
        //     [session setProperties:@{@"freshBoot":@YES, @"fromAd":@"shoes"}];
        // }] begin];

        // If you didn't know about a user at init, you can register them later like this
        [[Splyt Core] registerUser: [SplytEntityInfo createUserInfo:@"joe"] andThen:^(SplytError error) {
            XCTAssertTrue(SplytError_Success == error, @"Joe registration failed? Uh oh!");

            // transactions are the basic way to indicate that something has happened
            [[[Splyt Instrumentation] Transaction:@"JoeThing"] begin];
            [[[Splyt Instrumentation] Transaction:@"JoeThing"] end];

            // If you happen to know more about a user than just their id, use an init block
            SplytEntityInfo* userInfo = [SplytEntityInfo createUserInfo:@"josephine" withInitBlock:^(SplytEntityInfo *user) {
                [user setProperty:@"likes" withValue:@{@"sports":@YES, @"dolls":@NO, @"stereotypes":@YES}];
                [user setProperty:@"favoriteTeam" withValue:@"NYJ"];
            }];
            // NOTE: You can register more than one user at a time...
            [[Splyt Core] registerUser:userInfo andThen:^(SplytError error) {
                XCTAssertTrue(SplytError_Success == error, @"Josephine registration failed? Uh oh!");

                // transactions get more powerful when given state
                [[[Splyt Instrumentation] Transaction:@"MyTransaction" withId:@"12345" andInitBlock:^(SplytTransaction* t) {
                    [t setProperties:@{@"day" : @{@"value" : @1, @"ofWeek" : @"saturday"}}];
                }] begin];

                // ... other things may happen during the lifespan of my transaction

                // transaction id links the begin to the end, but other state properties do not need to be
                //  specified, unless they change
                [[[Splyt Instrumentation] Transaction:@"MyTransaction" withId:@"12345"] end];

                // if you have multiple concurrent users, just activate them as needed
                SplytError setActiveError = [[Splyt Core] setActiveUser:@"unregisteredGuy"];

                NSString* emptyKey = [[Splyt Tuning] getVar:nil orDefaultTo:@"default"];
                XCTAssertEqual(emptyKey, @"default");
                NSString* emptyVal = [[Splyt Tuning] getVar:@"empty" orDefaultTo:nil];
                XCTAssertNil(emptyVal);
                NSString* stringVal = [[Splyt Tuning] getVar:@"string" orDefaultTo:@"a string"];
                XCTAssertEqual(stringVal, @"a string");
                NSNumber* numVal = [[Splyt Tuning] getVar:@"number" orDefaultTo:@1];
                XCTAssertEqual(numVal, @1);

                // but users need to be registered before they can be used
                XCTAssertTrue(setActiveError == SplytError_InvalidArgs, @"You should have gotten an error for trying to activate an unregistered user");
                setActiveError = [[Splyt Core] setActiveUser:@"joe"];
                XCTAssertTrue(setActiveError == SplytError_Success, @"Joe was registered earlier.  This should work.");

                // the purchase plugin makes it easy to record purchases in a standard way
                [[[SplytPlugins Purchase] TransactionWithInitBlock:^(SplytPurchaseTransaction *purchase) {
                    [purchase setOfferId:@"NEWSHOES1"];
                    [purchase setItemName:@"Best shoes ever"];
                    [purchase setPrice:@100 inCurrency:@"usd"];
//                    [purchase setProperty:nil withValue:@"extra thing"];
//                    [purchase setProperty:@"nothing" withValue:nil];
                }] begin];

                // ...

                [[[SplytPlugins Purchase] Transaction] endWithResult:SPLYT_TXN_ERROR];

                // if all of your users log out, let Splyt know so that transactions will just be logged for the device
                [[Splyt Core] clearActiveUser];

                // collections are designed for currencies or other things which may be accumulated during the lifetime of the application
                [[Splyt Instrumentation] updateCollection:@"pairs of shoes" toBalance:@99 byAdding:@1 andTreatAsCurrency:NO];

                // collections already surface the latest balance, so you don't need to consider this as part of an entity's state
                //  but if you aren't using a collection, you can still update state
                [[Splyt Instrumentation] updateUserState:@{@"shoes owned":@99}];

                // Do a one-shot transaction
                [[[Splyt Instrumentation] Transaction:@"oneShot"] beginAndEndWithResult:@"oneShotResult!"];

                done = YES;
            }];
        }];
    }];

    while(!done) { sleep(1); }
}

@end
