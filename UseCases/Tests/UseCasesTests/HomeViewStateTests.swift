import XCTest
import UseCases
import Entities

@MainActor
final class HomeViewStateTests: XCTestCase {
    func testLoadUser() async {
        await XCTContext.runActivityAsync(named: "成功") { _ in
            let user: User = .init(id: "koher", name: "Yuta Koshizawa", introduction: "")

            await XCTContext.runActivityAsync(named: "user") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                XCTAssertNil(state.user)
                async let x: Void = state.loadUser()
                await Task.sleep()
                UserService.currentUserContinuation!.resume(returning: user)
                await x
                XCTAssertEqual(state.user, user)
            }

            await XCTContext.runActivityAsync(named: "isLoadingUser") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                XCTAssertFalse(state.isLoadingUser)
                async let x: Void = state.loadUser()
                await Task.sleep()
                XCTAssertTrue(state.isLoadingUser)
                UserService.currentUserContinuation!.resume(returning: user)
                await x
                XCTAssertFalse(state.isLoadingUser)
            }
        }
        
        await XCTContext.runActivityAsync(named: "失敗") { _ in
            await XCTContext.runActivityAsync(named: "認証エラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                XCTAssertFalse(state.presentsAuthenticationErrorAlert)
                async let x: Void = state.loadUser()
                await Task.sleep()
                UserService.currentUserContinuation!.resume(throwing: AuthenticationError())
                await x
                XCTAssertTrue(state.presentsAuthenticationErrorAlert)
            }
            
            await XCTContext.runActivityAsync(named: "ネットワークエラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                XCTAssertFalse(state.presentsNetworkErrorAlert)
                async let x: Void = state.loadUser()
                await Task.sleep()
                UserService.currentUserContinuation!.resume(throwing: NetworkError(cause: GeneralError(message: "")))
                await x
                XCTAssertTrue(state.presentsNetworkErrorAlert)
            }
            
            await XCTContext.runActivityAsync(named: "サーバーエラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                XCTAssertFalse(state.presentsServerErrorAlert)
                async let x: Void = state.loadUser()
                await Task.sleep()
                UserService.currentUserContinuation!.resume(throwing: ServerError.internal(cause: GeneralError(message: "")))
                await x
                XCTAssertTrue(state.presentsServerErrorAlert)
            }
            
            await XCTContext.runActivityAsync(named: "システムエラー") { _ in
                let state: HomeViewState<AuthService, UserService> = .init(dismiss: {})
                
                XCTAssertFalse(state.presentsSystemErrorAlert)
                async let x: Void = state.loadUser()
                await Task.sleep()
                UserService.currentUserContinuation!.resume(throwing: GeneralError(message: ""))
                await x
                XCTAssertTrue(state.presentsSystemErrorAlert)
            }
        }
    }
}

private enum AuthService: AuthServiceProtocol {
    
}

private enum UserService: UserServiceProtocol {
    static private(set) var currentUserContinuation: CheckedContinuation<User, Error>?
    
    static func currentUser() async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            currentUserContinuation = continuation
        }
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep() async {
        await withCheckedContinuation { continuation in
            Task<Void, Never> {
                continuation.resume()
            }
        }
    }
}
