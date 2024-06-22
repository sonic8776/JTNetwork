//
//  URLSessionHTTPClient.swift
//  JTNetwork
//
//  Created by Judy Tsai on 2024/6/18.
//

import Foundation

class URLSessionHTTPClient: HTTPClient {
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
            
            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data
            else {
                completion(.failure(.cannotFindDataOrResponse))
                return
            }
            
            completion(.success((data, response)))
        }.resume()
    }

    
}
