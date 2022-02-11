import UIKit
import Combine
import Entities
import UseCases
import APIServices
import Logging
import SwiftUI

// FIXME: 依存関係を整理して取り除く
extension AuthService: AuthServiceProtocol {}

@MainActor
final class LoginViewController: UIViewController {
    private let state: LoginViewState<AuthService> = .init()
    
    @IBOutlet private var idField: UITextField!
    @IBOutlet private var passwordField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            state.transitionToHomeView
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    // HomeView に遷移。
                    Task {
                        let destination = UIHostingController(rootView: HomeView(dismiss: { [weak self] in
                            await self?.dismiss(animated: true)
                        }))
                        destination.modalPresentationStyle = .fullScreen
                        destination.modalTransitionStyle = .flipHorizontal
                        await self.present(destination, animated: true)
                    }
                }
                .store(in: &cancellables)
        }
        
        do {
            state.$presentsActivityIndicator
                .sink { [weak self] presents in
                    guard let self = self else { return }
                    Task {
                        if presents {
                            let activityIndicatorViewController: ActivityIndicatorViewController = .init()
                            activityIndicatorViewController.modalPresentationStyle = .overFullScreen
                            activityIndicatorViewController.modalTransitionStyle = .crossDissolve
                            await self.present(activityIndicatorViewController, animated: true)
                        } else {
                            await self.dismiss(animated: true)
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
        do {
            state.$error
                .sink { [weak self] error in
                    guard let self = self else { return }
                    Task {
                        if let error = error {
                            let title: String
                            let message: String
                            if error is LoginError {
                                title = "ログインエラー"
                                message = "IDまたはパスワードが正しくありません。"
                            } else if error is NetworkError {
                                title = "ネットワークエラー"
                                message = "通信に失敗しました。ネットワークの状態を確認して下さい。"
                            } else if error is ServerError {
                                title = "サーバーエラー"
                                message = "しばらくしてからもう一度お試し下さい。"
                            } else {
                                title = "システムエラー"
                                message = "エラーが発生しました。"
                            }
                            let alertController: UIAlertController = .init(title: title, message: message, preferredStyle: .alert)
                            alertController.addAction(.init(title: "閉じる", style: .default, handler: nil))
                            await self.present(alertController, animated: true)
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
        do {
            state.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    self.loginButton.isEnabled = self.state.canLogin
                }
                .store(in: &cancellables)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // VC を表示する前に View の状態のアップデートし、状態の不整合を防ぐ。
        // loginButton は ID およびパスワードが空でない場合だけ有効。
        state.objectWillChange.send()
    }
    
    // ログインボタンが押されたときにログイン処理を実行。
    @IBAction private func loginButtonPressed(_ sender: UIButton) {
        Task {
            await state.logIn()
        }
    }
    
    // ID およびパスワードのテキストが変更されたときに View の状態を更新。
    @IBAction private func inputFieldValueChanged(sender: UITextField) {
        // loginButton は ID およびパスワードが空でない場合だけ有効。
        if sender === idField {
            state.id = sender.text ?? ""
        }
        if sender === passwordField {
            state.password = sender.text ?? ""
        }
    }
}
