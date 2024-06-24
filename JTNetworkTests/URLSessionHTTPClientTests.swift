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
    
    typealias HTTPClientResult = Result<(Data, HTTPURLResponse), HTTPClientError>
    
    static var sessionConfiguration: URLSessionConfiguration = .ephemeral
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest(forConfiguration: sessionConfiguration)
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    // MARK: - Failure Cases
    
    func test_request_failsOnGetRequestError() {
        let requestType = anyGETRequest
        let expectedError = anyError
        assertOnErrorResult(requestType: requestType, expectedError: expectedError)
    }
    
    func test_request_failsOnPostRequestError() {
        let requestType = anyPOSTRequest
        let expectedError = anyError
        assertOnErrorResult(requestType: requestType, expectedError: expectedError)
    }
    
    // MARK: - Happy Cases
    
    func test_request_succeedOnGetHTTPURLResponseWithData() {
        let requestType = anyGETRequest
        let expectedData = anyData
        let expectedResponse = anyGETHttpURLResponse
        assertOnValueResult(requestType: requestType, expectedData: expectedData, expectedResponse: expectedResponse)
    }
    
    func test_request_succeedOnPostHTTPURLResponseWithData() {
        let requestType = anyPOSTRequest
        let expectedData = anyData
        let expectedResponse = anyPOSTHttpURLResponse
        assertOnValueResult(requestType: requestType, expectedData: expectedData, expectedResponse: expectedResponse)
    }
    
    // MARK: - Edge Cases for successfully response
    
    func test_request_succeedWithNilDataOnGetHTTPURLResponseWithEmptyData() {
        let requestType = anyGETRequest
        let expectedResponse = anyGETHttpURLResponse
        let expectedData = Data()
        assertOnValueResult(requestType: requestType, expectedData: expectedData, expectedResponse: expectedResponse)
    }
    
    func test_request_succeedWithNilDataOnPostHTTPURLResponseWithEmptyData() {
        let requestType = anyPOSTRequest
        let expectedResponse = anyPOSTHttpURLResponse
        let expectedData = Data()
        assertOnValueResult(requestType: requestType, expectedData: expectedData, expectedResponse: expectedResponse)
    }
    
    func test_request_succeedOnGetHTTPURLResponseWithNilResponse() {
        let requestType = anyGETRequest
        let expectedError = HTTPClientError.cannotFindDataOrResponse
        assertOnValueResult(requestType: requestType, expectedData: nil, expectedResponse: nil, expectedError: expectedError)
    }
    
    func test_request_succeedOnPostHTTPURLResponseWithNilResponse() {
        let requestType = anyPOSTRequest
        let expectedError = HTTPClientError.cannotFindDataOrResponse
        assertOnValueResult(requestType: requestType, expectedData: nil, expectedResponse: nil, expectedError: expectedError)
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
    var anyData: Data { .init("any-data".utf8) }
    var anyPOSTBody: Data { .init("any-body".utf8) }
    
    var anyGETRequest: RequestTypeSpy {
        .init(path: "/any-path", method: .get, body: nil)
    }
    
    var anyPOSTRequest: RequestTypeSpy {
        .init(path: "/any-path", method: .post, body: anyPOSTBody)
    }
    
    var anyGETHttpURLResponse: HTTPURLResponse {
        .init(url: anyGETRequest.fullURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    var anyPOSTHttpURLResponse: HTTPURLResponse {
        .init(url: anyPOSTRequest.fullURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    var anyError: HTTPClientError {
        HTTPClientError.networkError
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let session = URLSession(configuration: URLSessionHTTPClientTests.sessionConfiguration)
        let sut = URLSessionHTTPClient(session: session)
        return sut
    }
    
    func makeResult(requestType: RequestTypeSpy, expectedData: Data?, expectedResponse: HTTPURLResponse?, expectedError: HTTPClientError?) -> HTTPClientResult {
        // Arrange
        let expectation = expectation(description: "Wait for completion...")
        URLProtocolStub.stub(data: expectedData, response: expectedResponse, error: expectedError)
        let sut = makeSUT()
        var receivedResult: Result<(Data, HTTPURLResponse), HTTPClientError>!
        
        // Action
        sut.request(withRequestType: requestType) { result in
            expectation.fulfill()
            receivedResult = result
        }
        wait(for: [expectation], timeout: 1.0)
        
        return receivedResult
    }
    
    func assertOnErrorResult(requestType: RequestTypeSpy, expectedError: HTTPClientError?, file: StaticString = #file, line: UInt = #line) {
        let receivedResult = makeResult(requestType: requestType, expectedData: nil, expectedResponse: nil, expectedError: expectedError)
        
        // Assert
        switch receivedResult {
        case let .failure(receivedError):
            XCTAssertEqual(expectedError, receivedError, file: file, line: line)
        default:
            XCTFail("Should receive error: \(expectedError)", file: file, line: line)
        }
    }
    
    func assertOnValueResult(requestType: RequestTypeSpy, expectedData: Data?, expectedResponse: HTTPURLResponse?, expectedError: HTTPClientError? = nil, file: StaticString = #file, line: UInt = #line) {
        let receivedResult = makeResult(requestType: requestType, expectedData: expectedData, expectedResponse: expectedResponse, expectedError: nil)
        // Assert
        switch receivedResult {
            
        case let .success((data, httpURLResposne)):
            XCTAssertEqual(data, expectedData, file: file, line: line)
            XCTAssertEqual(httpURLResposne.url, expectedResponse?.url, file: file, line: line)
            XCTAssertEqual(httpURLResposne.statusCode, expectedResponse?.statusCode, file: file, line: line)
            
            // 另一種寫法
//            let isEqual = httpURLResposne == expectedResponse
//            XCTAssertTrue(isEqual)
            
        case let .failure(httpClientError):
            XCTAssertEqual(httpClientError, expectedError)
            
//        default:
//            XCTFail("Should receive data: \(expectedData), response: \(expectedResponse)", file: file, line: line)
        }
    }
}

//extension HTTPURLResponse: Equatable {
//    
//    static func == (lhs: HTTPURLResponse, rhs: HTTPURLResponse) -> Bool {
//        lhs.statusCode == rhs.statusCode && lhs.url == rhs.url
//    }
//}
