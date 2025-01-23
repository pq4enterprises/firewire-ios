//
//  FeedsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/01/25.
//

final class FeedsListViewModel {
    var feedList: [FeedListData] = []
    var delegate: FeedListViewDelegate?

    func getFeedList(){
        var requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        let getFeedRequestModel = APIPayload.feedList(requestModel).toDictionary()

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.feedList,
            payload: getFeedRequestModel,
            expect: FeedListResponseModel.self,
            requestType: APIConstants.GET)
        { [weak self] response, _, _ in

            guard let apiResponse = response else {
                return
            }

            if let feedListResponse = apiResponse as? FeedListResponseModel {
                self?.feedList = feedListResponse.data
                self?.delegate?.dataReceived()
            }else{
                print("Invalid response object")
            }
        }
    }

}
