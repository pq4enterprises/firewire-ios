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
        guard let transaction, let userId = UserDefaults.standard.string(forKey: "user_id") else {
            delegate?.success(message: "Required payment details not available")
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
            requestType: APIConstants.PUT
        ) { [weak self] response, _, _ in
            guard let apiResponse = response else {
                self?.delegate?.success(message: "Payment detail submission failed, try again after sometime")
                return
            }

            if apiResponse is SuccessResponseModel {
                self?.delegate?.success(message: "Your premium subscription is Success!")
            } else {
                self?.delegate?.success(message: "Payment detail submission failed")
            }
        }
    }

    func getString(fromDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current // Set to the current time zone
        return formatter.string(from: fromDate)
    }
}
