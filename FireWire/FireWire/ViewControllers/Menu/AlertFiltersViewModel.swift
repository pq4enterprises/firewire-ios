//
//  AlertFiltersViewModel.swift
//  FireWire
//
//  Iteration 1 — per-locality alert picker (incident types + units).
//
//  Reads and writes the new alert-filter endpoints:
//    GET api/app/alert-filters/{localityId}
//    PUT api/app/alert-filters/{localityId}  { typeIds: null | [id], unitIds: null | [id] }
//  `null` means ALL (the server default — stored as nothing). This screen is
//  the only writer of those filters; the Areas & Alerts save path
//  (POST api/app/user/notification) is untouched.
//

import Foundation

// MARK: - Response models

struct AlertFiltersResponseModel: Codable {
    let message: String
    let code: String
    let data: AlertFiltersData?
}

struct AlertFiltersData: Codable {
    let locality: AlertFiltersLocality?
    let typesAll: Bool
    let unitsAll: Bool
    let types: [AlertFilterEntry]
    let units: [AlertFilterEntry]

    enum CodingKeys: String, CodingKey {
        case locality, typesAll, unitsAll, types, units
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locality = try container.decodeIfPresent(AlertFiltersLocality.self, forKey: .locality)
        // Missing flags default to ALL — the server's own default.
        typesAll = try container.decodeIfPresent(Bool.self, forKey: .typesAll) ?? true
        unitsAll = try container.decodeIfPresent(Bool.self, forKey: .unitsAll) ?? true
        types = try container.decodeIfPresent([AlertFilterEntry].self, forKey: .types) ?? []
        units = try container.decodeIfPresent([AlertFilterEntry].self, forKey: .units) ?? []
    }
}

struct AlertFiltersLocality: Codable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
    }
}

struct AlertFilterEntry: Codable {
    let id: String
    let name: String
    let checked: Bool

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, checked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        checked = (try? container.decode(Bool.self, forKey: .checked)) ?? false
    }
}

struct AlertFiltersUpdateResponseModel: Codable {
    let message: String
    let code: String
    let data: AlertFiltersUpdateData?
}

struct AlertFiltersUpdateData: Codable {
    let typesAll: Bool?
    let unitsAll: Bool?
    let typeCount: Int?
    let unitCount: Int?
}

// MARK: - View model

final class AlertFiltersViewModel {

    enum Section: Int, CaseIterable {
        case types
        case units

        var title: String {
            switch self {
            case .types: return "INCIDENT TYPES"
            case .units: return "UNITS"
            }
        }

        var allLabel: String {
            switch self {
            case .types: return "All incident types"
            case .units: return "All units"
            }
        }
    }

    struct Item {
        let id: String
        let name: String
        var checked: Bool
    }

    let localityId: String
    private(set) var localityName: String

    private(set) var typesAll = true
    private(set) var unitsAll = true
    private(set) var types: [Item] = []
    private(set) var units: [Item] = []

    /// Baselines for change detection.
    private var originalTypesAll = true
    private var originalUnitsAll = true
    private var originalTypeIds: Set<String> = []
    private var originalUnitIds: Set<String> = []

    /// Units search (prefix / substring, case-insensitive). Indices into `units`.
    private(set) var unitSearchText = ""
    private(set) var visibleUnitIndices: [Int] = []

    var onDataLoaded: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSaved: (() -> Void)?

    init(localityId: String, localityName: String) {
        self.localityId = localityId
        self.localityName = localityName
    }

    // MARK: Accessors

    func isAll(_ section: Section) -> Bool {
        section == .types ? typesAll : unitsAll
    }

    func items(in section: Section) -> [Item] {
        section == .types ? types : units
    }

    /// Row count shown under a section header (nothing when ALL is on).
    func visibleCount(in section: Section) -> Int {
        guard !isAll(section) else { return 0 }
        switch section {
        case .types: return types.count
        case .units: return visibleUnitIndices.count
        }
    }

    /// Maps a visible row back to its item index in the section's full list.
    func itemIndex(forRow row: Int, in section: Section) -> Int {
        switch section {
        case .types: return row
        case .units: return visibleUnitIndices[row]
        }
    }

    func item(forRow row: Int, in section: Section) -> Item {
        items(in: section)[itemIndex(forRow: row, in: section)]
    }

    func checkedCount(in section: Section) -> Int {
        items(in: section).filter { $0.checked }.count
    }

    /// A section with ALL off and nothing checked cannot be saved.
    func needsSelection(_ section: Section) -> Bool {
        !isAll(section) && checkedCount(in: section) == 0
    }

    /// True when every item currently visible in the section is checked
    /// (drives the SELECT ALL / SELECT NONE label).
    func allVisibleChecked(in section: Section) -> Bool {
        switch section {
        case .types:
            return !types.isEmpty && types.allSatisfy { $0.checked }
        case .units:
            return !visibleUnitIndices.isEmpty && visibleUnitIndices.allSatisfy { units[$0].checked }
        }
    }

    var hasChanges: Bool {
        if typesAll != originalTypesAll || unitsAll != originalUnitsAll { return true }
        if !typesAll, checkedIds(in: .types) != originalTypeIds { return true }
        if !unitsAll, checkedIds(in: .units) != originalUnitIds { return true }
        return false
    }

    private func checkedIds(in section: Section) -> Set<String> {
        Set(items(in: section).filter { $0.checked }.map { $0.id })
    }

    // MARK: Mutations

    func setAll(_ on: Bool, in section: Section) {
        switch section {
        case .types: typesAll = on
        case .units: unitsAll = on
        }
    }

    func toggle(row: Int, in section: Section) {
        let index = itemIndex(forRow: row, in: section)
        switch section {
        case .types: types[index].checked.toggle()
        case .units: units[index].checked.toggle()
        }
    }

    /// Checks or unchecks every item the user can currently see — for units,
    /// that is the search-filtered subset, so "select all" on "E-2" only
    /// touches the matching companies.
    func setVisible(checked: Bool, in section: Section) {
        switch section {
        case .types:
            for index in types.indices { types[index].checked = checked }
        case .units:
            for index in visibleUnitIndices { units[index].checked = checked }
        }
    }

    func setUnitSearch(_ text: String) {
        unitSearchText = text
        rebuildVisibleUnits()
    }

    private func rebuildVisibleUnits() {
        let query = unitSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            visibleUnitIndices = Array(units.indices)
            return
        }
        let folded = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        var prefixMatches: [Int] = []
        var substringMatches: [Int] = []
        for (index, unit) in units.enumerated() {
            let name = unit.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            if name.hasPrefix(folded) {
                prefixMatches.append(index)
            } else if name.contains(folded) {
                substringMatches.append(index)
            }
        }
        visibleUnitIndices = prefixMatches + substringMatches
    }

    // MARK: Load

    func load() {
        let endpoint = String(format: APIEndpoints.alertFilters, localityId)
        APIRequest().callApi(
            apiEndPoint: endpoint,
            expect: AlertFiltersResponseModel.self,
            requestType: APIConstants.GET
        ) { [weak self] response, _, error in
            guard let self else { return }
            if let error {
                self.onError?(error)
                return
            }
            guard let model = response as? AlertFiltersResponseModel, let data = model.data else {
                self.onError?((response as? AlertFiltersResponseModel)?.message ?? .CommonError.techError)
                return
            }
            self.apply(data)
            self.onDataLoaded?()
        }
    }

    private func apply(_ data: AlertFiltersData) {
        if let name = data.locality?.name, !name.isEmpty {
            localityName = name
        }
        typesAll = data.typesAll
        unitsAll = data.unitsAll
        types = data.types.map { Item(id: $0.id, name: $0.name, checked: $0.checked) }
        units = data.units.map { Item(id: $0.id, name: $0.name, checked: $0.checked) }

        originalTypesAll = typesAll
        originalUnitsAll = unitsAll
        originalTypeIds = checkedIds(in: .types)
        originalUnitIds = checkedIds(in: .units)
        rebuildVisibleUnits()
    }

    // MARK: Save

    /// PUT payload: `null` for a section whose ALL switch is on, otherwise the
    /// checked ids. A new subscriber never reaches here with nothing changed
    /// (the controller pops early), so the ALL/ALL default is never written.
    func savePayload() -> [String: Any] {
        [
            "typeIds": typesAll ? NSNull() : Array(checkedIds(in: .types)),
            "unitIds": unitsAll ? NSNull() : Array(checkedIds(in: .units)),
        ]
    }

    func save() {
        let endpoint = String(format: APIEndpoints.alertFilters, localityId)
        APIRequest().callApi(
            apiEndPoint: endpoint,
            payload: savePayload(),
            expect: AlertFiltersUpdateResponseModel.self,
            requestType: APIConstants.PUT
        ) { [weak self] response, _, error in
            guard let self else { return }
            if let error {
                self.onError?(error)
                return
            }
            guard let model = response as? AlertFiltersUpdateResponseModel,
                  model.code.lowercased() == "updated"
            else {
                self.onError?((response as? AlertFiltersUpdateResponseModel)?.message ?? .CommonError.techError)
                return
            }
            // New baseline so a second save on the same screen is a no-op.
            self.originalTypesAll = self.typesAll
            self.originalUnitsAll = self.unitsAll
            self.originalTypeIds = self.checkedIds(in: .types)
            self.originalUnitIds = self.checkedIds(in: .units)
            self.onSaved?()
        }
    }
}
