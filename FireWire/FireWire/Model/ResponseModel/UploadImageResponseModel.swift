//
//  UploadImageResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/01/25.
//

import Foundation

struct UploadImageResponseModel: Codable {
    let message: String
    let code: String
    let data: UploadImageData?
}

// MARK: - DataClass
struct UploadImageData: Codable {
    let link: [String]
    let url: [String]
}
