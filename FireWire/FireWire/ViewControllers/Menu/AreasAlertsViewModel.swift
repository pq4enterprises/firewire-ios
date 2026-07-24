//
//  AreasAlertsViewModel.swift
//  FireWire
//
//  2026 redesign — backs the combined "Areas & Alerts" screen that replaced
//  the personalization hub (Feed Areas + Notification Settings).
//
//  FEED toggles read/write the user's feed-area selection
//  (GET api/app/locality?type=area, POST api/app/user/area).
//  ALERT toggles read/write the user's push-notification selection
//  (GET api/app/locality?type=notification, POST api/app/user/notification).
//

import Foundation

final class AreasAlertsViewModel {

    struct AreaRow {
        let localityId: String
        let subLocalityId: String
        let name: String
        var feedOn: Bool
        /// Raw alert preference. Only effective (saved) when `feedOn` is also
        /// true — alerts without feed are not allowed.
        var alertOn: Bool
    }

    struct RegionGroup {
        let localityId: String
        let name: String
        var rows: [AreaRow]
        var allFeedOn: Bool {
            !rows.isEmpty && rows.allSatisfy { $0.feedOn }
        }
    }

    private(set) var groups: [RegionGroup] = []

    /// Baselines for change detection (sub-locality ids).
    private var originalFeedSet: Set<String> = []
    private var originalAlertSet: Set<String> = []

    /// The raw notification locality list. Units and incident types are only
    /// editable on the legacy drill-down screen, so their current selection is
    /// re-sent unchanged with every alert save — saving areas must never wipe
    /// them.
    private var notificationLocalities: [LocalityResponseData] = []

    var onDataLoaded: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSaved: (() -> Void)?

    // MARK: - Load

    func load() {
        let dispatchGroup = DispatchGroup()
        var areaData: [LocalityResponseData]?
        var notificationData: [LocalityResponseData]?
        var loadError: String?

        dispatchGroup.enter()
        fetchLocalities(.area) { result, error in
            areaData = result
            if let error { loadError = error }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchLocalities(.notification) { result, error in
            notificationData = result
            if let error { loadError = error }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }
            guard let areaData, let notificationData else {
                self.onError?(loadError ?? .CommonError.techError)
                return
            }
            self.buildGroups(areaData: areaData, notificationData: notificationData)
            self.onDataLoaded?()
        }
    }

    private func fetchLocalities(
        _ type: LocalityListType,
        completion: @escaping ([LocalityResponseData]?, String?) -> Void
    ) {
        var requestModel = IncidentLocalityRequestModel(sortBy: "createdAt", sortDir: "desc", offset: 1, limit: 10)
        requestModel.listType = ListType(type: type.rawValue)

        APIRequest().callApi(
            apiEndPoint: APIEndpoints.localityList,
            payload: APIPayload.incidentLocalityList(requestModel).toDictionary(),
            expect: LocalityResponseModel.self,
            requestType: APIConstants.GET
        ) { response, _, error in
            if let error {
                completion(nil, error)
                return
            }
            guard let localityResponse = response as? LocalityResponseModel,
                  let data = localityResponse.data
            else {
                completion(nil, .CommonError.techError)
                return
            }
            completion(data.data, nil)
        }
    }

    private func buildGroups(areaData: [LocalityResponseData], notificationData: [LocalityResponseData]) {
        notificationLocalities = notificationData

        var alertChecked: Set<String> = []
        for locality in notificationData {
            for subLocality in locality.subLocality where subLocality.isChecked {
                alertChecked.insert(subLocality.id)
            }
        }

        groups = areaData.map { locality in
            let rows = locality.subLocality.map { subLocality in
                AreaRow(
                    localityId: locality.id,
                    subLocalityId: subLocality.id,
                    name: subLocality.name,
                    feedOn: subLocality.isChecked,
                    alertOn: alertChecked.contains(subLocality.id))
            }
            return RegionGroup(localityId: locality.id, name: locality.name, rows: rows)
        }

        groups.sort { lhs, rhs in
            let lhsRank = Self.regionRank(lhs.name)
            let rhsRank = Self.regionRank(rhs.name)
            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        originalFeedSet = currentFeedSet
        originalAlertSet = alertChecked
    }

    /// Region display priority — first match wins; unlisted regions follow alphabetically.
    /// Adjust this list to change the on-screen order. Future: drive from a
    /// portal-managed Locality.sort field once the backend adds one.
    private static let regionOrder = [
        "NEW YORK CITY",
        "LONG ISLAND",
        "USA",
        "UNITED STATES",
        "CANADA",
        "EUROPE",
        "UNITED KINGDOM"
    ]

    private static func regionRank(_ name: String) -> Int {
        let key = name.trimmingCharacters(in: .whitespaces).uppercased()
        return regionOrder.firstIndex(of: key) ?? regionOrder.count
    }

    // MARK: - Mutations

    func toggleFeed(groupIndex: Int, rowIndex: Int) {
        groups[groupIndex].rows[rowIndex].feedOn.toggle()
    }

    func toggleAlert(groupIndex: Int, rowIndex: Int) {
        groups[groupIndex].rows[rowIndex].alertOn.toggle()
    }

    /// SELECT ALL / UNSELECT ALL toggles the FEED column for a whole region
    /// (matches the mockup — alerts are left untouched).
    func setFeedForAllRows(inGroup groupIndex: Int, on: Bool) {
        for index in groups[groupIndex].rows.indices {
            groups[groupIndex].rows[index].feedOn = on
        }
    }

    // MARK: - Change detection

    private var currentFeedSet: Set<String> {
        Set(groups.flatMap { $0.rows.filter { $0.feedOn }.map { $0.subLocalityId } })
    }

    /// Alerts that will actually be saved: alert-on AND feed-on.
    private var effectiveAlertSet: Set<String> {
        Set(groups.flatMap { $0.rows.filter { $0.feedOn && $0.alertOn }.map { $0.subLocalityId } })
    }

    var feedChanged: Bool { currentFeedSet != originalFeedSet }
    var alertChanged: Bool { effectiveAlertSet != originalAlertSet }
    var hasFeedSelection: Bool { !currentFeedSet.isEmpty }

    // MARK: - Save

    /// Commits both sets, only firing a request for the set that changed.
    func save() {
        let userId = FWUserDefaults().userID ?? ""
        let dispatchGroup = DispatchGroup()
        var failureMessage: String?

        if feedChanged {
            let payload: [[String: Any]] = groups.flatMap { group in
                group.rows.filter { $0.feedOn }.map {
                    SelectedAreaModel(
                        userId: userId,
                        localityId: $0.localityId,
                        subLocalityId: $0.subLocalityId
                    ).toDictionary()
                }
            }

            dispatchGroup.enter()
            APIRequest().callApi(
                apiEndPoint: APIEndpoints.setSelectedArea,
                payload: payload,
                expect: SuccessResponseModel.self
            ) { response, _, error in
                if let apiResponse = response as? SuccessResponseModel,
                   apiResponse.code.lowercased() == "updated" {
                    // Saved
                } else {
                    failureMessage = error ?? .CommonError.techError
                }
                dispatchGroup.leave()
            }
        }

        if alertChanged {
            dispatchGroup.enter()
            APIRequest().callApi(
                apiEndPoint: APIEndpoints.setNotificationArea,
                payload: alertPayload(userId: userId),
                expect: SuccessResponseModel.self
            ) { response, _, error in
                if let apiResponse = response as? SuccessResponseModel,
                   apiResponse.code.lowercased() == "updated" {
                    // Saved
                } else {
                    failureMessage = error ?? .CommonError.techError
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            if let failureMessage {
                self?.onError?(failureMessage)
            } else {
                self?.onSaved?()
            }
        }
    }

    private func alertPayload(userId: String) -> [[String: Any]] {
        var models: [SelectedNotificationModel] = []
        var localitiesWithChildren: Set<String> = []

        // Sub-locality alerts from this screen. Rows whose feed is off are
        // dropped — alerts without feed are not allowed.
        for group in groups {
            for row in group.rows where row.feedOn && row.alertOn {
                models.append(SelectedNotificationModel(
                    userId: userId,
                    notificationId: row.subLocalityId,
                    type: "subLocality",
                    forLocalityId: row.localityId))
                localitiesWithChildren.insert(row.localityId)
            }
        }

        // Preserve unit and incident-type selections this screen doesn't edit.
        for locality in notificationLocalities {
            for unit in (locality.unit ?? []).compactMap({ $0 }) where unit.isChecked {
                models.append(SelectedNotificationModel(
                    userId: userId,
                    notificationId: unit.id,
                    type: "unit",
                    forLocalityId: locality.id))
                localitiesWithChildren.insert(locality.id)
            }
            for incidentType in (locality.incidentType ?? []).compactMap({ $0 }) where incidentType.isChecked {
                models.append(SelectedNotificationModel(
                    userId: userId,
                    notificationId: incidentType.id,
                    type: "incidentType",
                    forLocalityId: locality.id))
                localitiesWithChildren.insert(locality.id)
            }
        }

        // One locality entry per locality that has at least one selected child
        // (same contract the legacy Notification Settings screens used).
        for localityId in localitiesWithChildren {
            models.append(SelectedNotificationModel(
                userId: userId,
                notificationId: localityId,
                type: "locality",
                forLocalityId: localityId))
        }

        return models.map { $0.toDictionary() }
    }
}
