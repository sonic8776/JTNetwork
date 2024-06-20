//
//  HTTPClientEndToEndTest.swift
//  JTNetworkTests
//
//  Created by Judy Tsai on 2024/6/18.
//

import XCTest
@testable import JTNetwork

class HTTPClientEndToEndTest: XCTestCase {
    // GET https://620962796df46f0017f4c4db.mockapi.io/users/userList?page=1&limit=10
    
    func test_request_onSuccessfulRequestCase() {
        let sut = makeSUT()
        let requestType = RequestTypeSpy(page: "1")
        let expectation = expectation(description: "Wait for completion!")
        sut.request(withRequestType: requestType) { result in
            switch result {
            case let .success(data, _):
                expectation.fulfill()
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    print(json)
                    let jsonCount = json?.keys.count // 幾筆資料
                    XCTAssertEqual(jsonCount, 10)
                    
                } catch {
                    assertionFailure("The API should be successful!")
                }
                
                return
            default:
                assertionFailure("The API should be successful!")
            }
        }
        wait(for: [expectation], timeout: 30)
    }
}

private extension HTTPClientEndToEndTest {
    struct RequestTypeSpy: RequestType {
        init(page: String) {
            queryItems =  [
                .init(name: "page", value: page),
                .init(name: "limit", value: "10")
            ]
        }
        
        var baseURL: URL { .init(string: "https://620962796df46f0017f4c4db.mockapi.io")! }
        
        var path: String { "/users/userList" }
        
        var queryItems: [URLQueryItem] = []
        
        var method: JTNetwork.HTTPMethod { .get }
        
        var body: Data? { nil }
        
        var headers: [String: String]? { nil }
    }
    
    func makeSUT() -> HTTPClient {
        let session = URLSession(configuration: .ephemeral) // 確保沒有 cache
        let sut = URLSessionHTTPClient(session: session)
        return sut
    }
    
    
}
