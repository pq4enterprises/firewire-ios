//
//  FeedsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/01/25.
//

import AVFAudio
import Foundation

final class FeedsListViewModel {
    var feedList: [FeedListData] = []
    var delegate: FeedListViewDelegate?
    var audioPlayer: AVAudioPlayer?
    var currentIndex: IndexPath?  // Track which row is currently playing

    func getFeedList() {
        let requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
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
            } else {
                print("Invalid response object")
            }
        }
    }

    func playAudio(_ urlString: String, index: IndexPath) {
        guard let url = URL(string: urlString) else {
            self.delegate?.errorPlayingAudio()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    self?.delegate?.errorPlayingAudio()
                    return
                }
                
                guard let data = data else {
                    self?.delegate?.errorPlayingAudio()
                    return
                }
                
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.prepareToPlay()
                    self?.audioPlayer?.play()
                } catch {
                    self?.delegate?.errorPlayingAudio()
                    print("Error playing audio from URL: \(error.localizedDescription)")
                }
            }
        }

        task.resume()
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentIndex = nil
    }
}
