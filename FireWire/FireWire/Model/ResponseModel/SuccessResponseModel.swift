//
//  SuccessResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/12/24.
//

import Foundation

struct SuccessResponseModel: Codable {
    var message: String = ""
    var code: String = ""
    let data: DataModel?

    enum CodingKeys: String, CodingKey {
        case message
        case code
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        code = try container.decodeIfPresent(String.self, forKey: .code) ?? ""
        data = try container.decodeIfPresent(DataModel.self, forKey: .data)

    }
}

struct DataModel: Codable {}
