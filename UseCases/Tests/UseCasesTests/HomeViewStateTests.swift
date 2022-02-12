import XCTest
import UseCases
import Entities

@MainActor
final class HomeViewStateTests: XCTestCase {
    func testLoadUser() async {
        await XCTContext.runActivityAsync(named: "成功") { _ in
            let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
            
            let user: User = .init(id: "koher", name: "Yuta Koshizawa", introduction: "")
            UserService._currentUser = .success(user)

            XCTAssertNil(state.user)
            await state.loadUser()
            XCTAssertEqual(state.user, user)
        }
        
        await XCTContext.runActivityAsync(named: "失敗") { _ in
            await XCTContext.runActivityAsync(named: "認証エラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                UserService._currentUser = .failure(AuthenticationError())
                
                XCTAssertFalse(state.presentsAuthenticationErrorAlert)
                await state.loadUser()
                XCTAssertTrue(state.presentsAuthenticationErrorAlert)
            }
            
            await XCTContext.runActivityAsync(named: "ネットワークエラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                UserService._currentUser = .failure(NetworkError(cause: GeneralError(message: "")))
                
                XCTAssertFalse(state.presentsNetworkErrorAlert)
                await state.loadUser()
                XCTAssertTrue(state.presentsNetworkErrorAlert)
            }
            
            await XCTContext.runActivityAsync(named: "サーバーエラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                UserService._currentUser = .failure(ServerError.internal(cause: GeneralError(message: "")))
                
                XCTAssertFalse(state.presentsServerErrorAlert)
                await state.loadUser()
                XCTAssertTrue(state.presentsServerErrorAlert)
            }
            
            await XCTContext.runActivityAsync(named: "システムエラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                UserService._currentUser = .failure(GeneralError(message: ""))
                
                XCTAssertFalse(state.presentsSystemErrorAlert)
                await state.loadUser()
                XCTAssertTrue(state.presentsSystemErrorAlert)
            }
        }
    }
}

private enum AuthService: AuthServiceProtocol {
    
}

private enum UserService: UserServiceProtocol {
    static var _currentUser: Result<User, Error>?
    
    static func currentUser() async throws -> User {
        try _currentUser!.get()
    }
}
