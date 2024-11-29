import XCTest

class SearchMoviesUseCaseTests: XCTestCase {

    let mock = MoviesPage.mock
    let requestValue = SearchMoviesUseCaseRequestValue(
        query: MovieQuery(query: "title1"),
        page: 0
    )

    func testSearchMoviesUseCase_whenSuccessfullyFetchesMoviesForQuery_thenQueryIsSavedInRecentQueries() {
        // given
        var useCaseCompletionCallsCount = 0
        let moviesQueriesRepository = MoviesQueriesRepositoryMock()
        let moviesRepository = MoviesRepositoryMock(
            result: .success(mock[0])
        )
        let useCase = DefaultSearchMoviesUseCase(
            moviesRepository: moviesRepository,
            moviesQueriesRepository: moviesQueriesRepository
        )

        // when
        _ = useCase.execute(
            requestValue: requestValue,
            cached: { _ in }
        ) { _ in
            useCaseCompletionCallsCount += 1
        }
        // then
        var recents = [MovieQuery]()
        moviesQueriesRepository.fetchRecentsQueries(maxCount: 1) { result in
            recents = (try? result.get()) ?? []
        }
        XCTAssertTrue(recents.contains(MovieQuery(query: "title1")))
        XCTAssertEqual(useCaseCompletionCallsCount, 1)
        XCTAssertEqual(moviesQueriesRepository.fetchCompletionCallsCount, 1)
        XCTAssertEqual(moviesRepository.fetchCompletionCallsCount, 1)
    }
    
    func testSearchMoviesUseCase_whenFailedFetchingMoviesForQuery_thenQueryIsNotSavedInRecentQueries() {
        //SearchMoviesUseCaseが失敗した場合に、検索クエリが「最近の検索履歴（recentqueries）」に保存されないことを確認するテストを書いてください
        // 1. MoviesQueriesRepository/MoviesRepositoryのmock
        let moviesRepositoryMock = MoviesRepositoryMock(
            result: .failure(MoviesRepositoryMockError.failedFetching)
        )
        let moviesQueriesRepositoryMock = MoviesQueriesRepositoryMock()

        let usecase = DefaultSearchMoviesUseCase(moviesRepository: moviesRepositoryMock, moviesQueriesRepository: moviesQueriesRepositoryMock)

        // 2. usecaseのexecute
        _ = usecase.execute(
            requestValue: requestValue,
            cached: { _ in },
            completion: { _ in }
        )

        // 3. assert
        XCTAssertEqual(moviesRepositoryMock.fetchCompletionCallsCount, 1, "fetchMoviesListが呼ばれていないため")
        XCTAssertEqual(moviesQueriesRepositoryMock.saveCompletionCallsCount, 0, "saveRecentQueryが呼ばれていないため")
        XCTAssertTrue(moviesQueriesRepositoryMock.recentQueries.isEmpty)
    }
}
