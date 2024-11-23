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
    }
    
    func test_whenErrorWithNSURLErrorCancelledReturned_shouldReturnCancelledError() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let cancelledError = NSError(domain: "network", code: NSURLErrorCancelled, userInfo: nil)
        let sut = DefaultNetworkService(config: config, sessionManager: NetworkSessionManagerMock(response: nil,
                                                                                                  data: nil,
                                                                                                  error: cancelledError as Error))
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
    }
    
    func test_whenErrorWithNSURLErrorNotConnectedToInternetReturned_shouldReturnNotConnectedError() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let error = NSError(domain: "network", code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        let sut = DefaultNetworkService(config: config, sessionManager: NetworkSessionManagerMock(response: nil,
                                                                                                  data: nil,
                                                                                                  error: error as Error))
        
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
        let sut = DefaultNetworkService(config: config, sessionManager: NetworkSessionManagerMock(response: nil,
                                                                                                  data: nil,
                                                                                                  error: error as Error),
                                        logger: networkErrorLogger)
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
