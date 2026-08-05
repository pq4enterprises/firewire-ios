//
//  SubscriptionManager.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 29/01/25.
//

import StoreKit

protocol SubscriptionManagerDelegate {
    /// failureMessage is nil on success AND on failures that need no alert
    /// (e.g. the user cancelled the purchase sheet themselves).
    func purchaseTransactionCompleted(success: Bool, transaction: Transaction?, failureMessage: String?)
}

class SubscriptionManager: NSObject {
    let AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID = "com.nycfirewire.monthautorenew"
    static let shared = SubscriptionManager()
    
    fileprivate var iapProducts: [Product] = []
    
    var delegate: SubscriptionManagerDelegate?

    /// Display price of the monthly subscription, once products are fetched.
    /// UI-only accessor — does not touch the purchase flow.
    var monthlyDisplayPrice: String? {
        iapProducts.first?.displayPrice
    }
    
    private override init() {
        super.init()
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
        var foundExpired = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productID == AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID {
                // Check if the subscription is still valid
                if let expirationDate = transaction.expirationDate, expirationDate > Date() {
                    print("Subscription is active. Restoring access.")
                    //await unlockPremiumFeatures(transaction: transaction)
                    delegate?.purchaseTransactionCompleted(success: true, transaction: transaction, failureMessage: nil)
                    return
                } else {
                    foundExpired = true
                    print("Subscription has expired.")
                }
            }
        }

        // No valid subscription — a restore that finds nothing is not a failed
        // purchase, so say what actually happened.
        let message = foundExpired
            ? "Your subscription has expired. Subscribe again to regain premium access."
            : "No previous subscription was found to restore."
        delegate?.purchaseTransactionCompleted(success: false, transaction: nil, failureMessage: message)
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
                    delegate?.purchaseTransactionCompleted(success: true, transaction: transaction, failureMessage: nil)
                case .unverified:
                    print("Transaction verification failed.")
                    delegate?.purchaseTransactionCompleted(success: false, transaction: nil, failureMessage: "Purchase failed, please try again!")
                }
            case .userCancelled:
                // The user backed out on purpose — no alert needed.
                print("User cancelled the purchase.")
                delegate?.purchaseTransactionCompleted(success: false, transaction: nil, failureMessage: nil)
            case .pending:
                print("Purchase is pending.")
                delegate?.purchaseTransactionCompleted(success: false, transaction: nil, failureMessage: "Your purchase is pending approval.")
            @unknown default:
                delegate?.purchaseTransactionCompleted(success: false, transaction: nil, failureMessage: "Purchase failed, please try again!")
            }
        } catch {
            print("Purchase failed: \(error)")
            delegate?.purchaseTransactionCompleted(success: false, transaction: nil, failureMessage: "Purchase failed, please try again!")
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
