//
//  LinkListResponseModel.swift
//  FireWire
//
//  Response model for GET api/app/link (portal-managed menu shortcut links).
//  The link Index endpoint wraps its payload in the standard app success
//  envelope: { message, code, data: { data: [...], pageInfo } }.
//

struct LinkListResponseModel: Codable {
    let message: String?
    let code: String?
    let data: LinkListPageData?
}

struct LinkListPageData: Codable {
    let data: [AppLinkData]?
    let pageInfo: PageInfo?
}

struct AppLinkData: Codable {
    let id: String?
    let name: String?
    let url: String?
    let imageUrl: String?
    let sort: Double?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, url, imageUrl, sort, createdAt
    }
}
