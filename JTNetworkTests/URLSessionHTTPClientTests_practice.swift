//
//  URLSessionHTTPClientTests_practice.swift
//  JTNetworkTests
//
//  Created by Judy Tsai on 2024/6/24.
//

import XCTest
@testable import JTNetwork

final class URLSessionHTTPClientTests_practice: XCTestCase {
    
    static let sessionConfiguration = URLSessionConfiguration.ephemeral
    
    // 8.
    override class func setUp() {
        URLProtocolStub.startInterceptingRequest(forConfiguration: URLSessionHTTPClientTests_practice.sessionConfiguration)
    }
    
    // 9.
    override class func tearDown() {
        URLProtocolStub.stopInterceptionRequest()
    }
    
    // MARK: - Failure Cases
    
    // 10.
    func test_request_failsOnGetRequestError() {
        let requestType = anyGETRequest
        let expectedError = HTTPClientError_practice.networkError
        let receivedError = makeErrorResult(with: requestType, data: nil, response: nil, error: expectedError)
        XCTAssertEqual(expectedError, receivedError)
    }
    
    // 11.
    func test_request_failsOnPostRequestError() {
        let requestType = anyPOSTRequest
        let expectedError = HTTPClientError_practice.networkError
        let receivedError = makeErrorResult(with: requestType, data: nil, response: nil, error: expectedError)
        XCTAssertEqual(expectedError, receivedError)
    }
    
    // MARK: - Happy Cases
    
    // 12.
    func test_request_succeedsOnGetHTTPURLResponseWithData() {
        let requestType = anyGETRequest
        let expectedData = anyData
        let expectedResponse = anyGETResponse
        let receivedResponse = makeValueResult(with: requestType, data: expectedData, response: expectedResponse, error: nil)
        XCTAssertEqual(expectedData, receivedResponse?.data)
        XCTAssertEqual(expectedResponse.url, receivedResponse?.response.url)
        XCTAssertEqual(expectedResponse.statusCode, receivedResponse?.response.statusCode)
    }
    
    // 13.
    func test_request_succeedsOnPostHTTPURLResponseWithData() {
        let requestType = anyPOSTRequest
        let expectedData = anyData
        let expectedResponse = anyPOSTResponse
        let receivedResponse = makeValueResult(with: requestType, data: expectedData, response: expectedResponse, error: nil)
        XCTAssertEqual(expectedData, receivedResponse?.data)
        XCTAssertEqual(expectedResponse.url, receivedResponse?.response.url)
        XCTAssertEqual(expectedResponse.statusCode, receivedResponse?.response.statusCode)
    }
}

// MARK: - Helpers

extension URLSessionHTTPClientTests_practice {
    
    var anyGETRequest: RequestTypeSpy {
        .init(path: "/any-path", method: .get, body: nil)
    }
    
    var anyPOSTRequest: RequestTypeSpy {
        .init(path: "/any-path", method: .post, body: anyPOSTBody)
    }
    
    var anyPOSTBody: Data {
        .init("any-body".utf8)
    }
    
    var anyGETResponse: HTTPURLResponse {
        .init(url: anyGETRequest.fullURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    var anyPOSTResponse: HTTPURLResponse {
        .init(url: anyPOSTRequest.fullURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    var anyData: Data {
        .init("any-data".utf8)
    }
    
    // 2.
    // Mock response completion
    struct ResponseStub {
        let data: Data?
        let resposne: URLResponse?
        let error: Error?
    }
    
    // 3.
    // Mock RequestType
    struct RequestTypeSpy: RequestType_practice {
        var baseURL: URL = URL(string: "https://any-url.com")!
        var path: String
        var queryItems: [URLQueryItem] = []
        var method: JTNetwork.HTTPMethod_practice
        var headers: [String : String]? = nil
        var body: Data?
        
        // Only provide parameters that need to test
        init(path: String, method: HTTPMethod_practice, body: Data?) {
            self.path = path
            self.method = method
            self.body = body
        }
    }
    
    // URLProtocol is a class
    // 4.
    class URLProtocolStub: URLProtocol {
        private static var responseStub: ResponseStub?
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            responseStub = ResponseStub(data: data, resposne: response, error: error)
        }
        
        // 開始攔截請求，要向 URLProtocol 註冊這個 class
        static func startInterceptingRequest(forConfiguration configuration: URLSessionConfiguration) {
            configuration.protocolClasses = [URLProtocolStub.self]
        }
        
        // 停止攔截請求，要向 URLProtocol 取消註冊這個 class
        static func stopInterceptionRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            responseStub = nil
        }
        
        // ----- override URLProtocol methods -----
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let responseStub = URLProtocolStub.responseStub else {
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            
            if let data = responseStub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let resposne = responseStub.resposne {
                client?.urlProtocol(self, didReceive: resposne, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = responseStub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // 一定要實作否則會 crash
        override func stopLoading() {}
    }
}

// MARK: - Factory Methods

extension URLSessionHTTPClientTests_practice {
    
    // 1.
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient_practice {
        let session = URLSession(configuration: URLSessionHTTPClientTests_practice.sessionConfiguration)
        let sut = URLSessionHTTPClient_practice(session: session)
        return sut
    }
    
    // 提供介面帶入模擬的 request 和 response
    // 回傳模擬的 HTTPClient request completion 回傳的型別，也就是 Result<(Data, HTTPURLResponse), HTTPClientError>
    // 5.
    func makeResult(with requestType: RequestType_practice, data: Data?, response: URLResponse?, error: Error?,
                    file: StaticString = #file, line: UInt = #line) -> Result<(Data, HTTPURLResponse), HTTPClientError_practice> {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedResult: Result<(Data, HTTPURLResponse), HTTPClientError_practice>!
        let expectation = expectation(description: "Wait for completion...")
        sut.request(withRequestType: requestType) { result in
            expectation.fulfill()
            receivedResult = result
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
    // 6.
    func makeErrorResult(with requestType: RequestType_practice, data: Data?, response: URLResponse?, error: Error?,
                         file: StaticString = #file, line: UInt = #line) -> HTTPClientError_practice? {
        let result = makeResult(with: requestType, data: data, response: response, error: error)
        switch result {
        case .failure(let error):
            return error
            
        default:
            XCTFail("Should return error: \(String(describing: error))")
            return nil
        }
    }
    
    // 7.
    func makeValueResult(with requestType: RequestType_practice, data: Data?, response: URLResponse?, error: Error?,
                         file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = makeResult(with: requestType, data: data, response: response, error: error)
        switch result {
        case let .success((data, response)):
            return (data, response)
            
        default:
            XCTFail("Should return data: \(String(describing: data)), response: \(String(describing: response)))")
            return nil
        }
    }
}
