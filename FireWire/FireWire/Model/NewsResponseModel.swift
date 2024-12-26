//
//  NewsResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 14/12/24.
//

import Foundation

struct NewsResponseModel: Codable {
    var channel: Channel
}

struct Channel: Codable {
    let title: String
    let item: [NewsItem]
}

struct Image: Codable {
    let url: String
    let title: String
    let link: String
    let width, height: String
}

struct NewsItem: Codable {
    let title: String
    let link: String
    let pubDate: String
    let category: [String]
    let description: String
}



