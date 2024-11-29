//
//  MoviesRepositoryMock.swift
//  ExampleMVVM
//  
//  Created by tomo on 2024/11/23
//  
//


class MoviesRepositoryMock: MoviesRepository {

    var result: Result<MoviesPage, Error>
    var fetchCompletionCallsCount = 0

    init(result: Result<MoviesPage, Error>) {
        self.result = result
    }

    func fetchMoviesList(
        query: MovieQuery,
        page: Int,
        cached: @escaping (MoviesPage) -> Void,
        completion: @escaping (Result<MoviesPage, Error>
        ) -> Void
    ) -> Cancellable? {
        completion(result)
        fetchCompletionCallsCount += 1
        return nil
    }
}
