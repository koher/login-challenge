import XCTest

extension XCTContext {
    @MainActor
    static func runActivityAsync<Result>(named name: String, block: @escaping (XCTActivity) async throws -> Result) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            let _: Void = runActivity(named: name, block: { activity in
                Task {
                    do {
                        let result = try await block(activity)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            })
        }
    }
    
    @MainActor
    static func runActivityAsync<Result>(named name: String, block: @escaping (XCTActivity) async -> Result) async -> Result {
        await withCheckedContinuation { continuation in
            let _: Void = runActivity(named: name, block: { activity in
                Task {
                    let result = await block(activity)
                    continuation.resume(returning: result)
                }
            })
        }
    }
}
