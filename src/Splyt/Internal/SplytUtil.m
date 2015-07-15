//
//  SplytUtil.m
//  Splyt
//
//  Created by Jeremy Paulding on 12/20/13.
//  Copyright (c) 2013 Row Sham Bow, Inc. All rights reserved.
//

#import <Splyt/SplytUtil.h>
#import <sys/time.h>

@implementation SplytUtil
static BOOL SplytUtil_isLoggingEnabled = YES; // default to YES for early-init
static NSArray* SplytUtil_validCurrencyCodes = nil;
static NSMutableDictionary* SplytUtil_currencyCodesBySymbol = nil;
+ (void) setLogEnabled:(BOOL)isEnabled {
    SplytUtil_isLoggingEnabled = isEnabled;
}
+ (void) logDebug:(NSString*)msg {
    if(SplytUtil_isLoggingEnabled) {
        NSLog(@"%@", msg);
    }
}
+ (void) logError:(NSString*)msg {
    if(SplytUtil_isLoggingEnabled) {
        NSLog(@"ERROR: %@", msg);
    }
}

+ (void) cacheCurrencyInfo {
    SplytUtil_validCurrencyCodes = [NSLocale ISOCurrencyCodes];

    NSArray* availLocales = [NSLocale availableLocaleIdentifiers];
    SplytUtil_currencyCodesBySymbol = [NSMutableDictionary dictionaryWithCapacity:availLocales.count];

    for(NSString* loc in availLocales) {
        NSLocale* curLocale = [NSLocale localeWithLocaleIdentifier:loc];
        NSString* currencySymbol = [curLocale objectForKey:NSLocaleCurrencySymbol];
        NSString* currencyCode = [curLocale objectForKey:NSLocaleCurrencyCode];

        if(nil != currencyCode && nil != currencySymbol) {
            NSMutableSet* possibleCodes = [SplytUtil_currencyCodesBySymbol valueForKey:currencySymbol];
            if(nil != possibleCodes) {
                [possibleCodes addObject:currencyCode];
            }
            else {
                // Create the set and add it to the dictionary
                possibleCodes = [NSMutableSet setWithCapacity:1];
                [possibleCodes addObject:currencyCode];
                [SplytUtil_currencyCodesBySymbol setValue:possibleCodes forKey:currencySymbol];
            }
        }
    }
}

// Given an input currency string, return a string that is valid currency string.
// This can be either a valid ISO 4217 currency code or a currency symbol (e.g., for real currencies),  or simply any other ASCII string (e.g., for virtual currencies)
// If one cannot be determined, this method returns "unknown"
+ (NSString*) getValidCurrencyString:(NSString*)currency {
    NSString* validCurrencyStr = nil;

    if ((nil == SplytUtil_validCurrencyCodes) || (nil == SplytUtil_currencyCodesBySymbol)) {
        [self cacheCurrencyInfo];
    }

    // First check if the string is already a valid ISO 4217 currency code (i.e., it's in the list of known codes)
    if (NSNotFound != [SplytUtil_validCurrencyCodes indexOfObject:[currency uppercaseString]]) {
        // It is, just return it
        validCurrencyStr = [currency uppercaseString];
    }
    else {
        // Not a valid currency code, is it a currency symbol?
        NSSet* possibleCodes = [SplytUtil_currencyCodesBySymbol valueForKey:[currency uppercaseString]];
        if (nil != possibleCodes) {
            // It's a valid symbol

            // If there is only one associated currency code, use it
            if (1 == [possibleCodes count]){
                validCurrencyStr = [possibleCodes anyObject];
            }
            else {
                // Ok, more than one code associated with this symbol
                // We make a best guess as to the actual currency code based on the user's locale.
                NSString* currencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
                if ([possibleCodes containsObject:currencyCode]) {
                    // The locale currency is in the list of possible codes
                    // It's pretty likely that this currency symbol refers to the locale currency, so let's assume that
                    // This is not a perfect solution, but it's the best we can do until Google and Amazon start giving us more than just currency symbols
                    validCurrencyStr = currencyCode;
                }
                else {
                    // We have no idea which currency this symbol refers to, so just set it to "unknown"
                    validCurrencyStr = @"unknown";
                }
            }
        }
        else {
            // This is not a known currency symbol, so it must be a virtual currency
            // Strip out any non-ASCII characters
            validCurrencyStr = [[NSString alloc] initWithData:[currency dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding];
        }
    }

    return validCurrencyStr;
}

// See http://stackoverflow.com/questions/358207/iphone-how-to-get-current-milliseconds
+ (NSNumber*) getTimestamp
{
    struct timeval tv;
    gettimeofday(&tv,NULL);
    long double perciseTimeStamp = tv.tv_sec + tv.tv_usec * 0.000001;
    return [NSNumber numberWithDouble:perciseTimeStamp];
}

@end

// "Hidden" C method for the currency conversion utility function.  We'll need access to this from other SDKs that sit on top of this one.
NSString* SplytUtil_getValidCurrencyString(NSString* currency)
{
    return [SplytUtil getValidCurrencyString:currency];
}

