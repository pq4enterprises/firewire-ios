//
//  SubscriptionManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 29/01/25.
//

import StoreKit

protocol SubscriptionManagerDelegate {
    func purchaseTransactionCompleted(success: Bool, transaction: Transaction?)
}

class SubscriptionManager: NSObject {
    let AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID = "com.nycfirewire.monthautorenew"
    static let shared = SubscriptionManager()
    
    fileprivate var iapProducts: [Product] = []
    
    var delegate: SubscriptionManagerDelegate?
    
    private override init() {
        super.init()
        observeTransactionUpdates()
    }

    func observeTransactionUpdates() {
        Task {
            for await result in Transaction.updates {

                if case .verified(let transaction) = result {
                    // Deliver the content to the user
                    await unlockPremiumFeatures(transaction: transaction)
                    delegate?.purchaseTransactionCompleted(success: true, transaction: transaction)
                    // Mark the transaction as finished
                    await transaction.finish()
                } else {
                    print("Transaction verification failed.")
                }

            }
        }
    }

    // Fetch products using StoreKit 2
    func fetchProducts() async {
        do {
            // Request products using StoreKit 2 async/await API
            let products = try await Product.products(for: [AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID])
            self.iapProducts = products
            
            // Optionally, you can display product info here
            for product in products {
                print("Product found: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            print("Failed to fetch products: \(error)")
        }
    }

    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productID == AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID {
                // Check if the subscription is still valid
                if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                    print("Subscription is active. Restoring access.")
                    //await unlockPremiumFeatures(transaction: transaction)
                    delegate?.purchaseTransactionCompleted(success: true, transaction: transaction)
                    return
                } else {
                    print("Subscription has expired.")
                }
            }
        }

        // If no valid subscription was found
        delegate?.purchaseTransactionCompleted(success: false, transaction: nil)
        print("No active subscriptions found.")
    }


    // Purchase product using StoreKit 2
    func purchaseMyProduct() async {
        guard !iapProducts.isEmpty else { return }
        
        let product = iapProducts[0]  // Assuming first product for simplicity
        do {
            // Start the purchase process using StoreKit 2's async purchase method
            let result = try await product.purchase()
            
            // Handle the result of the purchase
            switch result {
            case .success(let verificationResult):
                // Handle the successful purchase
                switch verificationResult {
                case .verified(let transaction):
                    print("Purchase successful: \(transaction)")
                    //await unlockPremiumFeatures(transaction: transaction)
                    delegate?.purchaseTransactionCompleted(success: true, transaction: transaction)
                case .unverified:
                    print("Transaction verification failed.")
                    delegate?.purchaseTransactionCompleted(success: false, transaction: nil)
                }
            case .userCancelled:
                print("User cancelled the purchase.")
                delegate?.purchaseTransactionCompleted(success: false, transaction: nil)
            case .pending:
                print("Purchase is pending.")
                delegate?.purchaseTransactionCompleted(success: false, transaction: nil)
            @unknown default:
                delegate?.purchaseTransactionCompleted(success: false, transaction: nil)
            }
        } catch {
            print("Purchase failed: \(error)")
            delegate?.purchaseTransactionCompleted(success: false, transaction: nil)
        }
    }
    
    // Unlock premium features (e.g., removing ads)
    func unlockPremiumFeatures(transaction: Transaction) async {
        // Store the premium status
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        
        // Optionally, handle expiration and check if the subscription is still valid
        if let expirationDate = transaction.expirationDate, expirationDate > Date() {
            // Subscription is active
            print("User's subscription is still active.")
        } else {
            // Subscription has expired
            print("User's subscription has expired.")
        }
        
        NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
    }
    
    // Check if the user has an active subscription (based on UserDefaults)
    func checkSubscriptionStatus() -> Bool {
        return UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    func checkActiveSubscriptions() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            
            if transaction.productID == AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID {
                // Handle the active subscription
                if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                    print("Subscription is active.")
                } else {
                    print("Subscription has expired.")
                }
            }
        }
    }
    
}
