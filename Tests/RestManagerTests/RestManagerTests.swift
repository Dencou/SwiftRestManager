import XCTest
@testable import RestManager

final class RestManagerTests: XCTestCase {
    
    let restMgr = RestManager(
        httpRequestMaker: RealHttpRawHttpRequestMaker(),
        authorizationProvider: MockAuthorizationProvider()
    )
    
    func test_getMethodRequestTest() async throws {
        
        print("test.....")
        
        let result = try await restMgr.makeRequest(
            SampleResponse.self,
            path: "/test",
            method: "GET",
            body: nil
        )
        print(result.status)
        
    }
    
    func test_deleteMethodRequestTest() async throws {
        
        let resultDelete = try await restMgr.delete(
            String.self,
            path: "/test"
        )
        print(resultDelete.status)
    }
}
