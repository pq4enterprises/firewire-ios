//
//  PaginationHandler.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 25/01/25.
//

protocol PaginatableViewModel {
    associatedtype DataType

    var currentPage: Int { get set }
    var totalPages: Int { get set }
    var limit: Int { get set }
    var items: [DataType] { get set }

    func fetchData(forPage page: Int, completion: @escaping (Result<[DataType], Error>) -> Void)
    func didFetchData(_ data: [DataType])
}

class PaginationHandler<T: PaginatableViewModel> {
    private var viewModel: T
    private var isLoading = false

    init(viewModel: T) {
        self.viewModel = viewModel
    }

    func loadNextPage() {
        guard viewModel.currentPage < viewModel.totalPages else {
            print("All pages have been fetched")
            return
        }

        guard !isLoading else {
            return
        }

        isLoading = true

        // Fetch the next page of data
        let nextPage = viewModel.currentPage + 1
        viewModel.fetchData(forPage: nextPage) { [weak self] result in
            switch result {
            case .success(let newItems):
                self?.viewModel.didFetchData(newItems)
                self?.viewModel.currentPage = nextPage  // Update the current page
                self?.isLoading = false
            case .failure(let error):
                print("Failed to fetch data: \(error)")
            }
        }
    }
}
