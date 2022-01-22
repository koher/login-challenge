import Combine
import Entities
import APIServices
import Logging

@MainActor
public final class LoginViewState: ObservableObject {
    @Published public var id: String = ""
    @Published public var password: String = ""
    
    @Published public private(set) var isLoggingIn: Bool = false
    public var canInput: Bool { !isLoggingIn }
    public var canLogin: Bool { !(id.isEmpty || password.isEmpty || isLoggingIn) }
    @Published public private(set) var presentsActivityIndicator: Bool = false
    
    @Published public var error: Error?
    
    private let _transitionToHomeView: PassthroughSubject<Void, Never> = .init()
    public var transitionToHomeView: AnyPublisher<Void, Never> { _transitionToHomeView.eraseToAnyPublisher() }
    
    // String(reflecting:) はモジュール名付きの型名を取得するため。
    private let logger: Logger = .init(label: String(reflecting: LoginViewState.self))
    
    public init() {
    }
    
    public func logIn() async {
        // Task.init で 1 サイクル遅れるので、
        // その間に再度ログインボタンが押された場合に
        // 処理が二重に実行されるのを防ぐ。
        if isLoggingIn { return }
        
        isLoggingIn = true
        
        // Activity Indicator を表示。
        presentsActivityIndicator = true
        
        do {
            // API を叩いて処理を実行。
            try await AuthService.logInWith(id: id, password: password)
            
            // Activity Indicator を非表示に。
            presentsActivityIndicator = false

            // HomeView に遷移。
            _transitionToHomeView.send()
        } catch {
            // ユーザーに詳細なエラー情報は提示しないが、
            // デバッグ用にエラー情報を表示。
            logger.info("\(error)")
            
            // Activity Indicator を非表示に。
            presentsActivityIndicator = false
            
            // アラートでエラー情報を表示。
            // ユーザーには不必要に詳細なエラー情報は提示しない。
            self.error = error
        }

        isLoggingIn = false
    }
}
