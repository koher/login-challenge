import Entities

public protocol UserServiceProtocol {
    static func currentUser() async throws -> User
}
