//
//  MyAccountViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 28/02/25.
//

import Foundation
import StoreKit

final class MyAccountViewModel {
    public var delegate: MyAccountViewDelegate?

    func submitPayment(transaction: Transaction?) {
        guard let transaction, let userId = FWUserDefaults().userID else {
            delegate?.dataLoaded(status: false, message: "Required payment details not available")
            return
        }

        // Map the transaction to the SubmitSubscriptionModel
        let requestModel = SubmitSubscriptionModel(
            userId: userId,
            paymentMethod: "App Store",
            paymentToken: transaction.deviceVerification.description,
            transactionId: transaction.id.description,
            amount: transaction.price?.description ?? "",
            currency: transaction.currency?.identifier ?? "",
            status: "success",
            purchaseDate: getString(fromDate: transaction.purchaseDate),
            expiredDate: getString(fromDate: transaction.expirationDate ?? Date()),
            type: transaction.productType.localizedDescription
        )

        let submitPaymentRequestModel = APIPayload.submitSubscriptionDetails(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.submitSubscriptionDetails,
            payload: submitPaymentRequestModel as JSON,
            expect: SuccessResponseModel.self,
            requestType: APIConstants.POST
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.dataLoaded(status: false, message: errorMessage)
                return
            }

            guard let apiResponse = response else {
                self?.delegate?.dataLoaded(status: false, message: "Payment detail submission failed, try again after sometime")
                return
            }

            if apiResponse is SuccessResponseModel {
                self?.getUserProfile() // subscription success, get user profile for updated role
            } else {
                self?.delegate?.dataLoaded(status: false, message: "Payment detail submission failed")
            }
        }
    }

    func getUserProfile(forSubscription: Bool = true) {
        APIRequest().callApi(
            apiEndPoint: APIEndpoints.userProfile,
            expect: GetUserProfileResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, error in
            if let errorMessage = error {
                self?.delegate?.dataLoaded(status: false, message: errorMessage)
                return
            }

            guard let apiResponse = response as? GetUserProfileResponseModel else {
                let errorMessage = (response == nil) ? "Invalid response" : "Unexpected response format"
                self?.delegate?.dataLoaded(status: false, message: errorMessage)
                return
            }

            if apiResponse.code != "success" {
                self?.delegate?.dataLoaded(status: false, message: apiResponse.message)
                return
            }

            guard let userData = apiResponse.data else {
                self?.delegate?.dataLoaded(status: false, message: "Missing user data")
                return
            }

            if let userRole = userData.role {
                FWUserDefaults.setStringForKey(key: .userRoleKey, value: userRole)
            }

            self?.delegate?.dataLoaded(status: true, message: forSubscription ? "Your premium subscription is success!" : "" )
        }
    }


    func getString(fromDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current // Set to the current time zone
        return formatter.string(from: fromDate)
    }
}
