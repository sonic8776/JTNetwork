//
//  URLSessionHTTPClientTests.swift
//  JTNetworkTests
//
//  Created by Judy Tsai on 2024/6/20.
//

import XCTest
@testable import JTNetwork

/*
 在撰寫單元測試的程式碼時，有個 3A 原則，來輔助設計測試程式，可以讓測試程式更好懂。3A 原則如下：
 Arrange: 初始化目標物件、相依物件、方法參數、預期結果，或是預期與相依物件的互動方式
 Action: 呼叫目標物件的方法
 Assert: 驗證是否符合預期
 */

class URLSessionHTTPClientTests: XCTestCase {
    static var sessionConfiguration: URLSessionConfiguration = .ephemeral
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest(forConfiguration: sessionConfiguration)
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_request_failsOnGetRequestError() {
        // Arrange
        let requestType = RequestTypeSpy(path: "/any-path", method: .get, body: nil)
        let expectedError = HTTPClientError.networkError
        let expectation = expectation(description: "Wait for completion...")
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        let sut = makeSUT()
        var receivedResult: Result<(Data, HTTPURLResponse), HTTPClientError>!
        
        // Action
        sut.request(withRequestType: requestType) { result in
            expectation.fulfill()
            receivedResult = result
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        switch receivedResult {
        case let .failure(receivedError):
            XCTAssertEqual(expectedError, receivedError)
        default:
            XCTFail("Should receive error: \(expectedError)")
        }
        
//        let requestType = RequestTypeSpy(path: "/any-path", method: .get, body: nil)
//        let expectedError = HTTPClientError.networkError
//        let receivedError = makeErrorResult(with: requestType, data: nil, response: nil, error: expectedError)
//        XCTAssertEqual(expectedError, receivedError)
    }
    
    func test_request_failsOnPostRequestError() {
        // Arrange
        let requestType = RequestTypeSpy(path: "/any-path", method: .post, body: nil)
        let expectedError = HTTPClientError.networkError
        let expectation = expectation(description: "Wait for completion...")
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        let sut = makeSUT()
        var receivedResult: Result<(Data, HTTPURLResponse), HTTPClientError>!
        
        // Action
        sut.request(withRequestType: requestType) { result in
            expectation.fulfill()
            receivedResult = result
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        switch receivedResult {
        case let .failure(receivedError):
            XCTAssertEqual(expectedError, receivedError)
        default:
            XCTFail("Should receive error: \(expectedError)")
        }
    }
}

// MARK: - Helpers
private extension URLSessionHTTPClientTests {
    struct ResponeStub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    class URLProtocolStub: URLProtocol {
        private static var stub: ResponeStub?
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = ResponeStub.init(data: data, response: response, error: error)
        }
        
        class func startInterceptingRequest(forConfiguration configuration: URLSessionConfiguration) {
            configuration.protocolClasses = [URLProtocolStub.self]
        }
        
        class func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stub else {
                client?.urlProtocolDidFinishLoading(self)
                return
            }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
    
    struct RequestTypeSpy: RequestType {
        var baseURL: URL { .init(string: "https://any-url.com")! }
        
        var path: String
        
        var queryItems: [URLQueryItem] = []
        
        var method: JTNetwork.HTTPMethod
        
        var body: Data?
        
        var headers: [String: String]? { nil }
        
        init(path: String, method: HTTPMethod, body: Data?) {
            self.path = path
            self.method = method
            self.body = body
        }
    }
}

// MARK: - Factory Methods
private extension URLSessionHTTPClientTests {
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let session = URLSession(configuration: URLSessionHTTPClientTests.sessionConfiguration)
        let sut = URLSessionHTTPClient(session: session)
        return sut
    }
    
    func makeResult(with requestType: RequestType, data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Result<(Data, HTTPURLResponse), HTTPClientError> {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        var receivedResult: Result<(Data, HTTPURLResponse), HTTPClientError>!
        let expectation = expectation(description: "Wait for completion...")
        sut.request(withRequestType: requestType) { result in
            expectation.fulfill()
            receivedResult = result
        }
        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
    func makeErrorResult(with requestType: RequestType, data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientError? {
        let result = makeResult(with: requestType, data: data, response: response, error: error)
        switch result {
        case .failure(let error):
            return error
            
        default:
            XCTFail("Should return error: \(String(describing: error))")
            return nil
        }
    }
    
    func makeValueResult(with requestType: RequestType, data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (Data, HTTPURLResponse)? {
        let result = makeResult(with: requestType, data: data, response: response, error: error)
        switch result {
        case let .success((data, httpURLResponse)):
            return (data, httpURLResponse)
            
        default:
            XCTFail("Should return data: \(data) and response: \(response)!")
            return nil
        }
    }
}
