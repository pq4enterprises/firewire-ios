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
    

    // MARK: Offer-code redemption (relaunch promo, 2026-10)
    //
    // A subscription can now start OUTSIDE product.purchase(): an offer code redeemed
    // from the App Store redemption URL in the relaunch email, the in-app redeem
    // sheet, or a renewal. Those transactions arrive through Transaction.updates /
    // currentEntitlements and were previously ignored until the user tapped
    // RESTORE PURCHASES. This path reports them to the server (same submitPayment
    // call as a purchase) so the role flips to premium on the next app open.

    private let submittedKey = "submittedStoreTransactionIDs"
    private var submittedTransactionIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: submittedKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: submittedKey) }
    }
    private var observerTask: Task<Void, Never>?
    private var isSyncing = false

    /// Call once at launch. Also drains transactions left unfinished by earlier
    /// builds (the purchase path never called finish()).
    func startTransactionObserver() {
        guard observerTask == nil else { return }
        observerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, case .verified(let transaction) = result else { continue }
                await self.handleExternalTransaction(transaction)
            }
        }
    }

    /// Re-check the live entitlement when the app becomes active or the user signs in.
    /// Only does work for a signed-in basic_user, so it is free for everyone else.
    func syncEntitlementsIfNeeded() async {
        guard !isSyncing, isSignedIn, isBasicUser else { return }
        isSyncing = true
        defer { isSyncing = false }
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, isActivePremium(transaction) else { continue }
            await handleExternalTransaction(transaction)
            return
        }
    }

    private var isSignedIn: Bool {
        let defaults = FWUserDefaults()
        return !(defaults.userID ?? "").isEmpty && !(defaults.userToken ?? "").isEmpty
    }

    private var isBasicUser: Bool {
        FWUserDefaults().userRole == "basic_user"
    }

    private func isActivePremium(_ transaction: Transaction) -> Bool {
        guard transaction.productID == AUTORENEW_SUBSCRIBE_PURCHASE_PRODUCT_ID,
              transaction.revocationDate == nil,
              let expiration = transaction.expirationDate else { return false }
        return expiration > Date()
    }

    private func handleExternalTransaction(_ transaction: Transaction) async {
        guard isActivePremium(transaction) else {
            await transaction.finish()
            return
        }
        // Not signed in yet: leave it unfinished so StoreKit re-delivers it, and
        // syncEntitlementsIfNeeded() picks it up right after sign-in.
        guard isSignedIn else { return }

        let id = String(transaction.id)
        if submittedTransactionIDs.contains(id) || !isBasicUser {
            await transaction.finish()
            return
        }

        let reported = await ExternalTransactionReporter.submit(transaction)
        guard reported else { return }
        submittedTransactionIDs.insert(id)
        await transaction.finish()
        await MainActor.run {
            NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
        }
    }

}

/// Bridges MyAccountViewModel's delegate callback into async/await for the
/// background offer-code path, where no view controller is on screen.
private final class ExternalTransactionReporter: MyAccountViewDelegate {
    private let viewModel = MyAccountViewModel()
    private var continuation: CheckedContinuation<Bool, Never>?

    static func submit(_ transaction: Transaction) async -> Bool {
        let reporter = ExternalTransactionReporter()
        return await withCheckedContinuation { continuation in
            reporter.continuation = continuation
            reporter.viewModel.delegate = reporter   // strong ref keeps the reporter alive
            reporter.viewModel.submitPayment(transaction: transaction)
        }
    }

    func dataLoaded(status: Bool, message: String) {
        viewModel.delegate = nil
        continuation?.resume(returning: status)
        continuation = nil
    }
}
