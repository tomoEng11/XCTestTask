import XCTest


class NetworkServiceTests: XCTestCase {
    
    private struct EndpointMock: Requestable {
        var path: String
        var isFullPath: Bool = false
        var method: HTTPMethodType
        var headerParameters: [String: String] = [:]
        var queryParametersEncodable: Encodable?
        var queryParameters: [String: Any] = [:]
        var bodyParametersEncodable: Encodable?
        var bodyParameters: [String: Any] = [:]
        var bodyEncoder: BodyEncoder = AsciiBodyEncoder()
        
        init(path: String, method: HTTPMethodType) {
            self.path = path
            self.method = method
        }
    }
    
    class NetworkErrorLoggerMock: NetworkErrorLogger {
        var loggedErrors: [Error] = []
        func log(request: URLRequest) { }
        func log(responseData data: Data?, response: URLResponse?) { }
        func log(error: Error) { loggedErrors.append(error) }
    }
    
    private enum NetworkErrorMock: Error {
        case someError
    }

    func test_whenMockDataPassed_shouldReturnProperResponse() {
        // モックデータが渡されたときに、DefaultNetworkService がそのデータを正しく返すかをテストしてください。

        let mockHTTPResponse = HTTPURLResponse(url: URL(string: "https://mock.test.com")!, statusCode: 200, httpVersion: nil, headerFields: [:])
        let mockData = mockMoviesPage.data(using: .utf8)!
        let mockSessionManager = NetworkSessionManagerMock(response: mockHTTPResponse, data: mockData , error: nil)

        let sut = DefaultNetworkService(config: NetworkConfigurableMock(), sessionManager: mockSessionManager)

        let expectation = expectation(description: "正しい型が返ってきませんでした")

        _ = sut.request(endpoint: EndpointMock(path: "http://mock.test.com", method: .get)) { result in
            switch result {
            case .success(let response):
                // TODO: assert
                XCTAssertEqual(response, mockData)
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }
        wait(for: [expectation], timeout: 3)
    }


    func test_whenErrorWithNSURLErrorCancelledReturned_shouldReturnCancelledError() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let cancelledError = NSError(domain: "network", code: NSURLErrorCancelled, userInfo: nil)
        let sut = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: nil,
                data: nil,
                error: cancelledError as Error)
        )

        //when
        _ = sut.request(endpoint: EndpointMock(path: "http://mock.test.com", method: .get)) { result in
            do {
                _ = try result.get()
                XCTFail("Should not happen")
            } catch let error {
                guard case NetworkError.cancelled = error else {
                    XCTFail("NetworkError.cancelled not found")
                    return
                }
                
                completionCallsCount += 1
            }
        }
        //then
        XCTAssertEqual(completionCallsCount, 1)
    }

    func test_whenStatusCodeEqualOrAbove400_shouldReturnhasStatusCodeError() {
        // ステータスコードが 400 以上の場合に、NetworkError.error が返され、正しいステータスコードを持っていることをテストしてください。
        let config = NetworkConfigurableMock()

        let cancelledError = NSError(domain: "network", code: 400, userInfo: nil)

        let httpsResponseMock = HTTPURLResponse(url: URL(string: "http://mock.test.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)!

        let sut = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: httpsResponseMock,
                data: nil,
                error: cancelledError as Error)
        )

        let expectation = expectation(description: "requestが失敗した時のStatusCodeが一致しません")

        _ = sut.request(endpoint: EndpointMock(path: "http://mock.test.com", method: .get)) { result in
            do {
                _ = try result.get()
                XCTFail("Should not happen")
            } catch let error as NetworkError { // NetworkErrorにキャスト
                switch error {
                case let .error(statusCode, _): // statusCodeを取得
                    XCTAssertTrue(statusCode >= 400)
                    expectation.fulfill()
                case .notConnected:
                    XCTFail("Not connected error should not happen")
                case .cancelled:
                    XCTFail("Cancelled error should not happen")
                case .generic(let underlyingError):
                    XCTFail("Generic error occurred: \(underlyingError)")
                case .urlGeneration:
                    XCTFail("URL generation error should not happen")
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 3)
    }

    func test_whenErrorWithNSURLErrorNotConnectedToInternetReturned_shouldReturnNotConnectedError() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let error = NSError(domain: "network", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let sut = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: nil,
                data: nil,
                error: error as Error)
        )

        //when
        _ = sut.request(endpoint: EndpointMock(path: "http://mock.test.com", method: .get)) { result in
            do {
                _ = try result.get()
                XCTFail("Should not happen")
            } catch let error {
                guard case NetworkError.notConnected = error else {
                    XCTFail("NetworkError.notConnected not found")
                    return
                }
                
                completionCallsCount += 1
            }
        }
        //then
        XCTAssertEqual(completionCallsCount, 1)
    }
    
    func test_whenhasStatusCodeUsedWithWrongError_shouldReturnFalse() {
        // NetworkError の hasStatusCode メソッドが、異なるエラータイプで false を返すことをテストしてください。

        let mockResponse = HTTPURLResponse(url: URL(string: "http://mock.test.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
        let error = NSError(domain: "network", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let expectation = expectation(description: "")

        let config = NetworkConfigurableMock()
        let sut = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: mockResponse,
                data: nil,
                error: error)
        )
        _ = sut.request(endpoint: EndpointMock(path: "http://mock.test.com", method: .get)) { result in
            do {
                _ = try result.get()
                XCTFail("想定外: requestが成功している")
            } catch let error as NetworkError{
                XCTAssertFalse(error.hasStatusCode(300))
                expectation.fulfill()
            } catch {
                XCTFail("想定外: NetworkError以外が発生している。")
            }
        }
        wait(for: [expectation], timeout: 3)
    }

    func test_whenhasStatusCodeUsed_shouldReturnCorrectStatusCode_() {
        //when
        let sut = NetworkError.error(statusCode: 400, data: nil)
        //then
        XCTAssertTrue(sut.hasStatusCode(400))
        XCTAssertFalse(sut.hasStatusCode(399))
        XCTAssertFalse(sut.hasStatusCode(401))
    }
    
    func test_whenErrorWithNSURLErrorNotConnectedToInternetReturned_shouldLogThisError() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let error = NSError(domain: "network", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let networkErrorLogger = NetworkErrorLoggerMock()
        let sut = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: nil,
                data: nil,
                error: error as Error),
            logger: networkErrorLogger
        )
        //when
        _ = sut.request(endpoint: EndpointMock(path: "http://mock.test.com", method: .get)) { result in
            do {
                _ = try result.get()
                XCTFail("Should not happen")
            } catch let error {
                guard case NetworkError.notConnected = error else {
                    XCTFail("NetworkError.notConnected not found")
                    return
                }
                
                completionCallsCount += 1
            }
        }
        
        //then
        XCTAssertEqual(completionCallsCount, 1)
        XCTAssertTrue(networkErrorLogger.loggedErrors.contains {
            guard case NetworkError.notConnected = $0 else { return false }
            return true
        })
    }
}
