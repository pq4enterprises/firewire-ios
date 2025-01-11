//
//  SuccessResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 20/12/24.
//

import Foundation

struct SuccessResponseModel: Codable {
    let message: String
    let code: String
    let data: DataModel?
}

struct DataModel: Codable {}
