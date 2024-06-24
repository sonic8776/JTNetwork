//
//  HTTPClient_practice.swift
//  JTNetwork
//
//  Created by Judy Tsai on 2024/6/24.
//

import Foundation

enum HTTPClientError_practice: Error {
    case networkError
}

protocol HTTPClient_practice {
    func request(withRequestType requestType: RequestType_practice, completion: @escaping (Result<(Data, HTTPURLResponse), HTTPClientError_practice>) -> Void)
}
