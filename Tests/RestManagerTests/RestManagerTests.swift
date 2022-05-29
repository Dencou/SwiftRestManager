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
    
    func test_restResource() async throws {
        
        let resource = RestResourceFactory.createResource(TestType.self, Int.self, path: "/users", restManager: restMgr)
        
        let allUsers = try await resource.getAll(queryParams: nil)
        
        for user in allUsers.body!{
            NSLog("User Name: \(user.name)")
            let fullUser = try await resource.getById(id: user.id)
            NSLog("User Name: \(fullUser.body?.id)")
        }
        
        NSLog("AllUsers: \(allUsers.body)")
        
    }
}


class TestType : Decodable{
    let name: String
    let email: String
    let id: Int
}
