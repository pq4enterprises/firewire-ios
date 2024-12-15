//
//  NewsDetailResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import Foundation

struct NewsDetailResponseModel: Codable {
    let id, title, link: String
    let url: String
    let type: String
    let deleted: Bool
    let createdAt, updatedAt: String
    let v: Int
    let modifiedBy: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, link, url, type, deleted, createdAt, updatedAt
        case v = "__v"
        case modifiedBy
    }
}
