import XCTest
@testable import RestManager

final class RestManagerTests: XCTestCase {
    func testExample() async throws {
        
        print("test.....")
        let restMgr = RestManager(
            httpRequestMaker: RealHttpRawHttpRequestMaker(),
            authorizationProvider: MockAuthorizationProvider()
        )
        let result = try await restMgr.makeRequest(
            SampleResponse.self,
            path: "/test",
            method: "GET",
            body: nil
        )
        print(result.status)
    }
}
