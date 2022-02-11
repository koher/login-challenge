import Combine
import Entities
import APIServices
import Logging

@MainActor
public final class HomeViewState<AuthService: AuthServiceProtocol, UserService: UserServiceProtocol>: ObservableObject {
    @Published public private(set) var user: User?
    
    @Published public private(set) var isReloading: Bool = false
    @Published public private(set) var isLoggingOut: Bool = false
    
    @Published public private(set) var presentsActivityIndocator: Bool = false
    @Published public var presentsAuthenticationErrorAlert: Bool = false
    @Published public var presentsNetworkErrorAlert: Bool = false
    @Published public var presentsServerErrorAlert: Bool = false
    @Published public var presentsSystemErrorAlert: Bool = false
    
    public let dismiss: () async -> Void
    
    private let logger: Logger = .init(label: String(reflecting: HomeViewState.self))

    public init(dismiss: @escaping () async -> Void) {
        self.dismiss = dismiss
    }
    
    public func load() async {
        await loadUser()
    }
    
    public func loadUser() async {
        // 処理が二重に実行されるのを防ぐ。
        if isReloading { return }
        
        // 処理中はリロードボタン押下を受け付けない。
        isReloading = true
        
        do {
            // API を叩いて User を取得。
            let user = try await UserService.currentUser()
            
            // 取得した情報を View に反映。
            self.user = user
        } catch let error as AuthenticationError {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsAuthenticationErrorAlert = true
        } catch let error as NetworkError {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsNetworkErrorAlert = true
        } catch let error as ServerError {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsServerErrorAlert = true
        } catch {
            logger.info("\(error)")
            
            // エラー情報を表示。
            presentsSystemErrorAlert = true
        }
        
        // 処理が完了したのでリロードボタン押下を再度受け付けるように。
        isReloading = false
    }
    
    public func logOut() async {
        // 処理が二重に実行されるのを防ぐ。
        if isLoggingOut { return }
        
        // 処理中はログアウトボタン押下を受け付けない。
        isLoggingOut = false
        
        // Activity Indicator を表示。
        presentsActivityIndocator = true
        
        // API を叩いて処理を実行。
        await AuthService.logOut()
        
        // Activity Indicator を非表示に。
        presentsActivityIndocator = false
        
        // LoginViewController に遷移。
        await dismiss()
        
        // この View から遷移するのでボタンの押下受け付けは再開しない。
        // 遷移アニメーション中に処理が実行されることを防ぐ。
    }
}
