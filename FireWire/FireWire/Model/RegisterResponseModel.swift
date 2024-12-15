//
//  RegisterResponseModel.swift
//  FireWire
//
//  Created by Sujitha Palanisamy on 12/12/24.
//

import Foundation

struct RegisterResponseModel: Codable {
    let message: String?
    let code: String?
    let error: String?
}
