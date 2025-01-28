//
//  SubscriptionManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 29/01/25.
//

import StoreKit

class SubscriptionManager: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    let AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID = "com.nycfirewire.monthautorenew"
    static let shared = SubscriptionManager()

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

//    func startSubscriptionPurchase(productID: String) {
//        let payment = SKPayment(product: productID)
//        SKPaymentQueue.default().add(payment)
//    }

    // Fetch products from App Store
    func fetchProducts() {
        let productIDs = Set([AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID]) // Your subscription product ID(s)
        let request = SKProductsRequest(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }

    // Handle received products
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("DID RECEIVE RESPONSE FOR PRODUCT REQUEST: \(response)")
        print(": \(response.invalidProductIdentifiers)")
        print(": \(response.products)")
        
        for product in response.products {
            // This is where you would display the product info (name, price, etc.) in your app
            print("Product found: \(product.localizedTitle) - \(product.price)")
        }
    }

    // Handle transaction updates (purchase success, failure, restore, etc.)
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("Purchase successful!")
                // Unlock premium features, such as removing ads
                unlockPremiumFeatures()
                SKPaymentQueue.default().finishTransaction(transaction)

            case .failed:
                print("Purchase failed!")
                SKPaymentQueue.default().finishTransaction(transaction)

            case .restored:
                print("Purchase restored!")
                unlockPremiumFeatures()
                SKPaymentQueue.default().finishTransaction(transaction)

            default:
                break
            }
        }
    }

    // Unlock premium features (e.g., removing ads)
    func unlockPremiumFeatures() {
        UserDefaults.standard.set(true, forKey: "isPremiumUser") // Save this flag
        NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
    }

    // Check if the user has an active subscription
    func checkSubscriptionStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
}
