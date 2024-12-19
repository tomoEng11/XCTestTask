//
//  NetworkServiceMock.swift
//  ExampleMVVMTests
//  
//  Created by tomo on 2024/12/15
//  
//

import Foundation

final class NetworkServiceMock: NetworkService {
    var data: Data?
    var error: Error?
    
    func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.success(data ?? Data()))
    }

    func request(endpoint: any Requestable, completion: @escaping CompletionHandler) -> (any NetworkCancellable)? {
        return nil
    }
}
