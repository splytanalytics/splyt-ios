//
//  SplytUtil.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/20/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

@import Foundation;

NS_ROOT_CLASS
@interface SplytUtil
+ (void) setLogEnabled:(BOOL)isEnabled;
+ (void) logDebug:(NSString*)msg;
+ (void) logError:(NSString*)msg;
+ (void) cacheCurrencyInfo;
+ (NSString*) getValidCurrencyString:(NSString*)currency;
+ (NSNumber*) getTimestamp;
@end
