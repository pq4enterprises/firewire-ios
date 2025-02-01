//
//  SubscriptionManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 29/01/25.
//

import StoreKit

protocol SubscriptionManagerDelegate {
    func purchaseTransactionCompleted(success: Bool)
}

class SubscriptionManager: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    let AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID = "com.nycfirewire.monthautorenew"
    static let shared = SubscriptionManager()
    
    fileprivate var iapProducts = [SKProduct()]
    
    var delegate: SubscriptionManagerDelegate?

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    func purchaseMyProduct(){
        if iapProducts.count == 0 { return }
        
        if self.canMakePurcahse(){
            let payment = SKPayment(product: iapProducts[0])
            SKPaymentQueue.default().add(payment)
            
            print("PRODUCT TO PURCHASE: \(iapProducts[0].productIdentifier)")
        }
    }
    
    func canMakePurcahse() -> Bool {
        AppStore.canMakePayments
    }

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
        
        if (response.products.count > 0){
            iapProducts = response.products
        }
        
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
                delegate?.purchaseTransactionCompleted(success: true)

            case .failed:
                print("Purchase failed!")
                SKPaymentQueue.default().finishTransaction(transaction)
                delegate?.purchaseTransactionCompleted(success: false)

            case .restored:
                print("Purchase restored!")
                unlockPremiumFeatures()
                SKPaymentQueue.default().finishTransaction(transaction)
                delegate?.purchaseTransactionCompleted(success: false)

            default:
                break
            }
        }
    }

    //TODO: Temporary status to find premium user, this needs to be updated
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
