//
//  URLSessionHTTPClient_practice.swift
//  JTNetwork
//
//  Created by Judy Tsai on 2024/6/24.
//

import Foundation

class URLSessionHTTPClient_practice: HTTPClient_practice {
    
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func request(withRequestType requestType: RequestType_practice, completion: @escaping (Result<(Data, HTTPURLResponse), HTTPClientError_practice>) -> Void) {
        session.dataTask(with: requestType.urlRequest) { data, response, error in
            
            if let error {
                completion(.failure(.networkError))
                return
            }
            
            guard let data,
                  let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                completion(.failure(.cannotFindDataOrResponse))
                return
            }
            completion(.success((data, response)))
            
        }.resume()
    }
}
