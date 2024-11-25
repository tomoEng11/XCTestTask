//
//  MoviesQueriesRepositoryMock.swift
//  ExampleMVVM
//
//  Created by tomo on 2024/11/23
//
//


class MoviesQueriesRepositoryMock: MoviesQueriesRepository {
    var recentQueries: [MovieQuery] = []
    var fetchCompletionCallsCount = 0
    var saveCompletionCallsCount = 0

    func fetchRecentsQueries(
        maxCount: Int,
        completion: @escaping (Result<[MovieQuery], Error>) -> Void
    ) {
        completion(.success(recentQueries))
        fetchCompletionCallsCount += 1
    }
    func saveRecentQuery(query: MovieQuery, completion: @escaping (Result<MovieQuery, Error>) -> Void) {
        recentQueries.append(query)
        saveCompletionCallsCount += 1
    }
}
