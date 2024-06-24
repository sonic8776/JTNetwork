//
//  RequestType_practice.swift
//  JTNetwork
//
//  Created by Judy Tsai on 2024/6/24.
//

import Foundation

enum HTTPMethod_practice: String {
    case get = "GET"
    case post = "POST"
}

protocol RequestType_practice {
    var baseURL: URL { get } // var, get
    var path: String { get }
    var queryItems: [URLQueryItem] { get } // URLQueryItem
    var fullURL: URL { get }
    var method: HTTPMethod_practice { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
    var urlRequest: URLRequest { get }
}

extension RequestType_practice {
    var fullURL: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path += path
        components?.queryItems = queryItems
        guard let url = components?.url else {
            fatalError("Invalid URL components \(String(describing: components))")
        }
        return url
    }
    
    var urlRequest: URLRequest {
        var request = URLRequest(url: fullURL) // var
        request.httpMethod = method.rawValue
        request.httpBody = body
        if let headers {
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }
        return request
    }
}
