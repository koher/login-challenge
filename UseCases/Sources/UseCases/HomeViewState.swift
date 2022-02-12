import Combine
import Entities
import Logging

@MainActor
public final class HomeViewState<AuthService: AuthServiceProtocol, UserService: UserServiceProtocol>: ObservableObject {
    @Published public private(set) var user: User?
    
    @Published private var loadingUserState: LoadingUserState = .waiting
    
    public var isLoadingUser: Bool {
        guard case .loading = loadingUserState else { return false }
        return true
    }
    
    public var presentsAuthenticationErrorAlert: Bool {
        get {
            guard case .failure(is AuthenticationError) = loadingUserState else { return false }
            return true
        }
        set { if !newValue { loadingUserState.clearError() } }
    }
    
    public var presentsNetworkErrorAlert: Bool {
        get {
            guard case .failure(is NetworkError) = loadingUserState else { return false }
            return true
        }
        set { if !newValue { loadingUserState.clearError() } }
    }
    
    public var presentsServerErrorAlert: Bool {
        get {
            guard case .failure(is ServerError) = loadingUserState else { return false }
            return true
        }
        set { if !newValue { loadingUserState.clearError() } }
    }
    
    public var presentsSystemErrorAlert: Bool {
        get {
            switch loadingUserState {
            case .waiting, .loading, .failure(is AuthenticationError), .failure(is NetworkError), .failure(is ServerError): return false
            case .failure(_): return true
            }
        }
        set { if !newValue { loadingUserState.clearError() } }
    }

    @Published public private(set) var isLoggingOut: Bool = false
@Published public private(set) var presentsActivityIndocator: Bool = false
    
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
        if isLoadingUser { return }
        
        // 処理中はリロードボタン押下を受け付けない。
        loadingUserState.startLoading()
        
        do {
            // API を叩いて User を取得。
            let user = try await UserService.currentUser()
            
            // 取得した情報を View に反映。
            self.user = user
            
            // 処理が完了したのでリロードボタン押下を再度受け付けるように。
            loadingUserState.finishLoading()
        } catch {
            logger.info("\(error)")
            
            // エラー情報を表示。
            loadingUserState.failLoading(with: error)
        }
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

extension HomeViewState {
    private enum LoadingUserState {
        case waiting
        case loading
        case failure(Error)
        
        mutating func startLoading() {
            guard case .waiting = self else {
                assertionFailure()
                return
            }
            self = .loading
        }
        
        mutating func finishLoading() {
            guard case .loading = self else {
                assertionFailure()
                return
            }
            self = .waiting
        }
        
        mutating func failLoading(with error: Error) {
            guard case .loading = self else {
                assertionFailure()
                return
            }
            self = .failure(error)
        }
        
        mutating func clearError() {
            guard case .failure(_) = self else {
                assertionFailure()
                return
            }
            self = .waiting
        }
    }
}
