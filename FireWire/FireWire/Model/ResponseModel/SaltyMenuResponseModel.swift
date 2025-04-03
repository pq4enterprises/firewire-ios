//
//  SaltyMenuResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 03/04/25.
//

import Foundation

struct SaltyMenuResponseModel: Codable {
    let message, code: String
    let data: SaltyMenuDataModel?
}

struct SaltyMenuDataModel: Codable {
    let data: [SaltyMenuData]
    //let pageInfo: PageInfo
}

struct SaltyMenuData: Codable {
    let id, title: String
    let link: String
    let url: String
    let type, createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, link, url, type, createdAt
    }
}
