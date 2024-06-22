//
//  HTTPClient.swift
//  JTNetwork
//
//  Created by Judy Tsai on 2024/6/18.
//

import Foundation

enum HTTPClientError: Error {
    case networkError
    case cannotFindDataOrResponse
    
    
}

protocol HTTPClient {
    func request(withRequestType requestType: RequestType, completion: @escaping (Result<(Data, HTTPURLResponse), HTTPClientError>) -> Void)
}
