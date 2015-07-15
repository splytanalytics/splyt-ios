//
//  SplytUtil.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/20/13.
//  Copyright (c) 2013 Row Sham Bow, Inc. All rights reserved.
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
