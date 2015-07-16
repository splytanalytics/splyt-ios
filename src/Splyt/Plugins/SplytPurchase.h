//
//  SplytPurchase.h
//  Splyt
//
//  Copyright 2015 Knetik, Inc. All rights reserved.
//

#import <Splyt/SplytConstants.h>
#import <Splyt/SplytInstrumentation.h>

/**
 * @brief A light wrapper around SplytTransaction that makes it easy to report purchasing flows in your app.
 */
@interface SplytPurchaseTransaction : SplytTransaction

/**
 Reports the price of the item being purchased.

 @param amount The price of the item.
 @param currency The currency code (e.g., <code>"usd"</code>) that applies to `amount`.
 */
- (void) setPrice:(NSNumber*) amount inCurrency:(NSString*) currency;

/**
 Reports an offer ID for the item being purchased. Useful for identifying promotions or other application-defined offers.

 @param offerId The offer ID.
 */
- (void) setOfferId:(NSString*)offerId;

/**
 Reports the name of the item being purchased.

 @param itemName The item name.
 */
- (void) setItemName:(NSString*)itemName;

/**
 Reports the point of sale. Useful in situations where an application may have multiple points of purchase.

 @param pointOfSale An application-defined point of sale.
 */
- (void) setPointOfSale:(NSString*)pointOfSale;

@end

/**
 @brief Provides factory methods for creating a SplytPurchaseTransaction.
 */
@interface SplytPurchase : NSObject
/**
 Factory method used to create an instance of SplytPurchaseTransaction.

 @return The created SplytPurchaseTransaction.
*/
- (SplytPurchaseTransaction*) Transaction;

/**
 Factory method used to create an instance of SplytPurchaseTransaction.

 @param transactionId A unique identifier for the created transaction.  This is only required in situations
        where multiple purchase transactions may exist for the same user at the same time.
 @return The created SplytPurchaseTransaction.
 */
- (SplytPurchaseTransaction*) TransactionWithId:(NSString*)transactionId;

/**
 Factory method used to create an instance of SplytPurchaseTransaction.

 @param initBlock A callback function that can be used to set the initial properties for the purchase transaction.
        To do this, call SplytTransaction::setProperty:withValue: or
        SplytTransaction::setProperties: on the instance of SplytPurchaseTransaction passed to the `initBlock` callback.
 @return The created SplytPurchaseTransaction.
 */
- (SplytPurchaseTransaction*) TransactionWithInitBlock:(void(^)(SplytPurchaseTransaction*)) initBlock;

/**
 Factory method used to create an instance of SplytPurchaseTransaction.

 @param transactionId A unique identifier for the created transaction.  This is only required in situations
        where multiple purchase transactions may exist for the same user at the same time.
 @param initBlock A callback function that can be used to set the initial properties for the purchase transaction.
        To do this, call SplytTransaction::setProperty:withValue: or
        SplytTransaction::setProperties: on the instance of SplytPurchaseTransaction passed to the `initBlock` callback.
 @return The created SplytPurchaseTransaction.
 */
- (SplytPurchaseTransaction*) TransactionWithId:(NSString*)transactionId andInitBlock:(void(^)(SplytPurchaseTransaction*)) initBlock;
@end
