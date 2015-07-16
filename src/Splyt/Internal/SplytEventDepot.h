//
//  SplytEventDepot.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/16/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytInternal.h>
#import <Splyt/SplytConstants.h>

typedef NSDictionary*(^SplytEventSender)(NSString* url, NSArray* args);

@interface SplytEventDepot : NSObject
- (id) init __attribute__((unavailable("Use -initWithSender")));
- (id) initWithURL:(NSString*)url andSender:(SplytEventSender)sender;
- (SplytError) storeEvent:(NSString*)eventName withArgs:(NSArray*)args;
- (void) pause;
- (void) resume;
@end
