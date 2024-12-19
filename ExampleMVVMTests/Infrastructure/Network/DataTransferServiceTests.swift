import XCTest

private struct MockModel: Decodable {
    let name: String
}

final class DataTransferDispatchQueueMock: DataTransferDispatchQueue {
    func asyncExecute(work: @escaping () -> Void) {
        work()
    }
}

class DataTransferServiceTests: XCTestCase {
    
    private enum DataTransferErrorMock: Error, Equatable {
        case someError
    }
    
    func test_whenReceivedValidJsonInResponse_shouldDecodeResponseToDecodableObject() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let responseData = #"{"name": "Hello"}"#.data(using: .utf8)
        let networkService = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: nil,
                data: responseData,
                error: nil
            )
        )
        
        let sut = DefaultDataTransferService(with: networkService)
        //when
        _ = sut.request(
            with: Endpoint<MockModel>(path: "http://mock.endpoint.com", method: .get),
            on: DataTransferDispatchQueueMock()
        ) { result in
            do {
                let object = try result.get()
                XCTAssertEqual(object.name, "Hello")
                completionCallsCount += 1
            } catch {
                XCTFail("Failed decoding MockObject")
            }
        }
        //then
        XCTAssertEqual(completionCallsCount, 1)
    }
    
    func test_whenInvalidResponse_shouldNotDecodeObject() {
        // 無効なレスポンスデータを受け取った場合に、デコードが失敗することをテストしてください。

        let mock = NetworkServiceMock()
        let responseData = #"{"nam": "Hello"}"#.data(using: .utf8)
        mock.data = responseData
        let mockError = DataTransferErrorMock.someError
        mock.error = mockError
        let expectation = expectation(description: "無効なレスポンスデータを受け取った場合に、デコードが失敗することが確認できませんでした")
        let sut = DefaultDataTransferService(with: mock)
        _ = sut.request(
            with: Endpoint<MockModel>(path: "http://mock.endpoint.com",method: .get),
            completion: { result in
                do {
                    _ = try result.get()
                    XCTFail("想定外:正しいResponseが返ってきている")
                } catch {
                    switch error {
                    case DataTransferError.parsing(let error):
                        XCTAssertEqual(error as! DataTransferError, mockError)
                        expectation.fulfill()
                        return
                    case DataTransferError.noResponse:
                        return
                    case DataTransferError.networkFailure(let error):
                        return
                    case DataTransferError.resolvedNetworkFailure(let error):
                        return
                    default:
                        break
                    }
                }
            })

        wait(for: [expectation], timeout: 3)

    }

    func test_whenBadRequestReceived_shouldRethrowNetworkError() {
        // ステータスコードが 400 以上（この場合は 500）でレスポンスが返された場合に、適切なネットワークエラーが発生することをテストしてください。
    }
    
    func test_whenNoDataReceived_shouldThrowNoDataError() {
        //given
        let config = NetworkConfigurableMock()
        var completionCallsCount = 0
        
        let response = HTTPURLResponse(url: URL(string: "test_url")!,
                                       statusCode: 200,
                                       httpVersion: "1.1",
                                       headerFields: [:])
        let networkService = DefaultNetworkService(
            config: config,
            sessionManager: NetworkSessionManagerMock(
                response: response,
                data: nil,
                error: nil
            )
        )
        
        let sut = DefaultDataTransferService(with: networkService)
        //when
        _ = sut.request(
            with: Endpoint<MockModel>(path: "http://mock.endpoint.com", method: .get),
            on: DataTransferDispatchQueueMock()
        ) { result in
            do {
                _ = try result.get()
                XCTFail("Should not happen")
            } catch let error {
                if case DataTransferError.noResponse = error {
                    completionCallsCount += 1
                } else {
                    XCTFail("Wrong error")
                }
            }
        }
        //then
        XCTAssertEqual(completionCallsCount, 1)
    }
}
