public protocol AuthServiceProtocol {
    static func logInWith(id: String, password: String) async throws
    static func logOut() async
}
