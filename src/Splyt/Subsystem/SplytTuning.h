//
//  SplytTuning.h
//  Splyt
//
//  Created by Jeremy Paulding on 12/6/13.
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytConstants.h>

/**
 @brief Provides access to SPLYT's dynamic tuning variables.
 @details Tuning variables are defined in SPLYT's web app and can have customized values on a per-user
          basis, depending on whether the active user of the app is participating in an A/B test, or
          belongs to a segment of users that has been assigned customized values for one or more
          tuning variables.
 */
@interface SplytTuning : NSObject
/**
 Retrieves updated values from SPLYT for all tuning variables.

 If multiple users are registered (see SplytCore::registerUser:andThen:), updated values
 will be retrieved for all of them.

 @param callback An application-defined callback which will be called on completion.
 */
- (void) refreshAndThen:(SplytCallback)callback;
/**
 Gets the value of a named tuning variable from Splyt.

 > **Note:** This is not an async or blocking operation. Tuning values are proactively cached by
 > the SPLYT framework during SplytCore::init:andThen:, SplytCore::registerUser:andThen:,
 > and SplytTuning::refreshAndThen:

 @param varName Application-defined name of a tuning variable to retrieve.
 @param defaultValue A default value for the tuning variable, used when a dynamic value has not
        been specified or is otherwise not available.
 @return The dynamic value of the variable, or the default value (if the dynamic value could not
   be retrieved).
   > **Note:** The return value is guaranteed to match the type of `defaultValue`. If a dynamic value is set in
   > SPLYT which cannot be converted into the proper type, the default will be returned.
   >
   > All tuning variable values are either of type `NSNumber *` or `NSString *`, but they are returned
   > as `id`. You can cast the returned value to the appropriate type.
 */
- (id) getVar:(NSString*)varName orDefaultTo:(id)defaultValue;
@end

