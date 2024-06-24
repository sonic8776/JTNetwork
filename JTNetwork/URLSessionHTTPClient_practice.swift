//
//  URLSessionHTTPClient_practice.swift
//  JTNetwork
//
//  Created by Judy Tsai on 2024/6/24.
//

import Foundation

class URLSessionHTTPClient_practice: HTTPClient {
    
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func request(withRequestType requestType: RequestType, completion: @escaping (Result<(Data, HTTPURLResponse), HTTPClientError>) -> Void) {
        session.dataTask(with: requestType.urlRequest) { data, response, error in
            
            if let error {
                completion(.failure(.networkError))
                return
            }
            
            if let data, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                completion(.success((data, response)))
                return
            } else {
                completion(.failure(.networkError))
                return
            }
            
        }.resume()
    }
}
