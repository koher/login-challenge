import SwiftUI
import Entities
import UseCases
import APIServices

@MainActor
struct HomeView: View {
    @StateObject private var state: HomeViewState<AuthService, UserService>

    init(dismiss: @escaping () async -> Void) {
        self._state = .init(wrappedValue: HomeViewState(dismiss: dismiss))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Color(UIColor.systemGray4))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 0) {
                        Text(state.user?.name ?? "User Name")
                            .font(.title3)
                            .redacted(reason: state.user?.name == nil ? .placeholder : [])
                        Text((state.user?.id.rawValue).map { id in "@\(id)" } ?? "@ididid")
                            .font(.body)
                            .foregroundColor(Color(UIColor.systemGray))
                            .redacted(reason: state.user?.id == nil ? .placeholder : [])
                    }
                    
                    let introduction = state.user?.introduction ?? "Introduction. Introduction. Introduction. Introduction. Introduction. Introduction."
                    if let attributedIntroduction = try? AttributedString(markdown: introduction) {
                        Text(attributedIntroduction)
                            .font(.body)
                            .redacted(reason: state.user?.introduction == nil ? .placeholder : [])
                    } else {
                        Text(introduction)
                            .font(.body)
                            .redacted(reason: state.user?.introduction == nil ? .placeholder : [])
                    }
                    
                    // リロードボタン
                    Button {
                        Task {
                            await state.loadUser()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(state.isLoadingUser)
                }
                .padding()
                
                Spacer()
                
                // ログアウトボタン
                Button("Logout") {
                    Task {
                        await state.logOut()
                    }
                }
                .disabled(state.isLoggingOut)
                .padding(.bottom, 30)
            }
        }
        .alert(
            "認証エラー",
            isPresented: $state.presentsAuthenticationErrorAlert,
            actions: {
                Button("OK") {
                    Task {
                        // LoginViewController に遷移。
                        await state.dismiss()
                    }
                }
            },
            message: { Text("再度ログインして下さい。") }
        )
        .alert(
            "ネットワークエラー",
            isPresented: $state.presentsNetworkErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("通信に失敗しました。ネットワークの状態を確認して下さい。") }
        )
        .alert(
            "サーバーエラー",
            isPresented: $state.presentsServerErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("しばらくしてからもう一度お試し下さい。") }
        )
        .alert(
            "システムエラー",
            isPresented: $state.presentsSystemErrorAlert,
            actions: { Text("閉じる") },
            message: { Text("エラーが発生しました。") }
        )
        .activityIndicatorCover(isPresented: state.presentsActivityIndocator)
        .task {
            await state.loadUser()
        }
    }
}
