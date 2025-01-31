//
//  FeedsListViewModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 23/01/25.
//

import AVFAudio
import Foundation

final class FeedsListViewModel: PaginatableViewModel {
    typealias DataType = FeedListData

    var currentPage: Int = 1
    var totalPages: Int = 1
    var limit: Int = 10
    var items: [FeedListData] = []
    var delegate: FeedListViewDelegate?
    var audioPlayer: AVAudioPlayer?
    var currentIndex: IndexPath?  // Track which row is currently playing

    func fetchData(forPage page: Int, completion: @escaping (Result<[FeedListData], any Error>) -> Void) {
        let requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: page, limit: limit)
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
                let newItems = feedListResponse.data
                self?.totalPages = feedListResponse.pageInfo.totalCount
                DispatchQueue.main.async {
                    completion(.success(newItems))
                }
            } else {
                print("Invalid response object")
            }
        }
    }

    func didFetchData(_ data: [FeedListData]) {
        items.append(contentsOf: data) // Append new items to existing list
        delegate?.dataReceived()
    }

    func getFeedList(){
        fetchData(forPage: currentPage) { [weak self] result in
            switch result {
            case .success(let newItems):
                self?.didFetchData(newItems)
            case .failure(let error):
                print("Error fetching incidents: \(error)")
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
                    self?.items[index.row].isPlaying = true
                    self?.delegate?.playingAudio()
                } catch {
                    self?.delegate?.errorPlayingAudio()
                    print("Error playing audio from URL: \(error.localizedDescription)")
                }
            }
        }

        task.resume()
    }

    func stopAudio(index: IndexPath) {
        audioPlayer?.stop()
        audioPlayer = nil
        currentIndex = nil
        items[index.row].isPlaying = false
    }
}
