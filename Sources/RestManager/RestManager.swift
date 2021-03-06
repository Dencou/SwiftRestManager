import RealHTTP
import AFNetworking
import Foundation

public typealias ParamMap = [String: String]?

public struct RestManager {
    
    public private(set) var baseUrl = "https://jdenco.free.beeceptor.com"
    
    public var httpRequestMaker: RawHttpRequestMaker
    
    public var authorizationProvider: AuthorizationTokenProvider

    public init(
        httpRequestMaker: RawHttpRequestMaker,
        authorizationProvider: AuthorizationTokenProvider
    ) {
        self.httpRequestMaker = httpRequestMaker
        self.authorizationProvider = authorizationProvider
    }
    
    public func makeRequest<T : Decodable>(
        _ type: T.Type,
        path: String,
        method: String,
        body: AnyObject? = nil,
        queryParams: ParamMap? = nil
    )  async throws -> Response<T> {
        
        NSLog("HttpRequest\nMethod: \(method), Path: \(path) waiting.")
        
        let headers = [
            "Authorization": authorizationProvider.getUserAuthorizationToken(),
            "Accept": "application/json"
        ]
        
        let rawResponse = try await self.httpRequestMaker.makeRequest(
            url: self.baseUrl.appending(path),
            path: path,
            method: method,
            body: body,
            queryParams: queryParams,
            headers: headers,
            responseType: nil
        )
        
        NSLog("HttpResponse\nMethod: \(method), Path: \(path), StatusCode: \(rawResponse.status)")
        
        let data: Data = rawResponse.body!.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        var body: T? = nil
        do {
            body = try decoder.decode(_: T.self, from: data)
        } catch {
            NSLog("Failed to decode response: \(rawResponse.body)")
        }
        
        return Response<T>(
            body: body,
            status: rawResponse.status,
            headers: rawResponse.headers,
            url: rawResponse.url
        )
    }
    
    public func delete<T : Decodable>(
        _ type : T.Type,
        path: String,
        queryParams: ParamMap? = nil
    )async throws -> Response<T>{
        return try await makeRequest(type, path: path, method: "DELETE", queryParams: queryParams)
    }
    
    public func get<T : Decodable>(
        _ type: T.Type,
        path: String,
        queryParams: ParamMap? = nil
    ) async throws -> Response<T>  {
        return try await makeRequest(type, path: path, method: "GET", queryParams: queryParams)
    }
    
    public func post<T : Decodable>(
        _ type: T.Type,
        path: String,
        body: AnyObject,
        queryParams: ParamMap? = nil
    ) async throws -> Response<T>  {
        return try await makeRequest(type, path: path, method: "POST", body: body, queryParams: queryParams)
    }
}


public protocol RawHttpRequestMaker {
    func makeRequest(
        url: String,
        path: String,
        method: String,
        body: AnyObject?,
        queryParams: ParamMap?,
        headers: ParamMap?,
        responseType: AnyClass?
    ) async throws -> Response<String>
}

public protocol AuthorizationTokenProvider {
    func getUserAuthorizationToken() -> String
}

public class MockAuthorizationProvider: AuthorizationTokenProvider {
    public func getUserAuthorizationToken() -> String {
        return "Bearer ...."
    }
}

public class RealHttpRawHttpRequestMaker: RawHttpRequestMaker {
    
    public func makeRequest(
        url: String,
        path: String,
        method: String,
        body: AnyObject?,
        queryParams: ParamMap?,
        headers: ParamMap?,
        responseType: AnyClass? = nil
    ) async throws -> Response<String> {
        let req = HTTPRequest {
            // Setup default params
            $0.url = URL(string: url)!
            switch method {
            case "POST":
                $0.method = .post
            case "DELETE":
                $0.method = .delete
            case "PATCH":
                $0.method = .patch
            case "PUT":
                $0.method = .put
            case "OPTIONS":
                $0.method = .options
            case "HEAD":
                $0.method = .head
            default:
                $0.method = .get
            }
            $0.timeout = 15
            $0.headers = HTTPHeaders(rawDictionary: headers!)
            $0.path = url

            // Setup some additional settings
            $0.maxRetries = 4
            // Setup URL query params & body
            $0.addQueryParameter(name: "full", value: "1")
            $0.addQueryParameter(name: "autosignout", value: "30")
        }
        let response = try await req.fetch()
        return Response(
            body: response.data?.asString,
            status: response.statusCode.rawValue,
            headers: response.headers.asDictionary,
            url: url
        )
    }
    
}

public class MockRawHttpRequestMaker: RawHttpRequestMaker {
    public func makeRequest(
        url: String,
        path: String,
        method: String,
        body: AnyObject?,
        queryParams: ParamMap?,
        headers: ParamMap?,
        responseType: AnyClass? = nil
    ) -> Response<String> {
        return Response(
            body: "{}",
            status: 200,
            headers: nil,
            url: url
        )
    }
}


@main
public class Main{
    static func main() async throws {
        print("test.....")
        let restMgr = RestManager(
            httpRequestMaker: MockRawHttpRequestMaker(),
            authorizationProvider: MockAuthorizationProvider()
        )
        let result = try await restMgr.makeRequest(
            SampleResponse.self,
            path: "/test",
            method: "GET"
        )
        print(result)
    }
}

class SampleResponse : Decodable {
    var status: String
    init(status: String? = nil) {
        if let status = status {
            self.status = status
        }else{
            self.status = "no-status"
        }
    }
}


public class Response<T> {
    var body: T? = nil
    var status: Int = 0
    var headers: ParamMap?
    var url: String
    init (
        body: T? = nil,
        status: Int = 0,
        headers: ParamMap? = nil,
        url: String
    ) {
        self.body = body
        self.headers = headers
        self.status = status
        self.url = url
    }
}

public class RestResource<T : Decodable, ID> {
    let path: String
    let type: T.Type
    let idType: ID.Type
    let restManager: RestManager
    init (
        _ type: T.Type,
        _ idType: ID.Type,
        path: String,
        restManager: RestManager
    ){
        self.path = path
        self.idType = idType
        self.type = type
        self.restManager = restManager
    }
    func getById(id: ID)  async throws -> Response<T> {
        return try await restManager.get(
            T.self,
            path: "\(self.path)/\(id)",
            queryParams: nil
        )
    }
    func delete(id: ID)  async throws -> Response<T> {
        return try await restManager.delete(
            T.self,
            path: "\(self.path)/\(id)",
            queryParams: nil
        )
    }
    func post(body: AnyObject)  async throws -> Response<T> {
        return try await restManager.post(
            T.self,
            path: self.path,
            body: body,
            queryParams: nil
        )
    }
    func patch(id: ID, body: AnyObject)  async throws -> Response<T> {
        return try await restManager.makeRequest(
            T.self,
            path: "\(self.path)/\(id)",
            method: "PATCH",
            body: body,
            queryParams: nil
        )
    }
    func put(id: ID, body: AnyObject)  async throws -> Response<T> {
        return try await restManager.makeRequest(
            T.self,
            path: "\(self.path)/\(id)",
            method: "PATCH",
            body: body,
            queryParams: nil
        )
    }
    func getAll(queryParams: ParamMap?)  async throws -> Response<[T]> {
        return try await restManager.get(
            [T].self,
            path: self.path,
            queryParams: queryParams
        )
    }
}

public class RestResourceFactory {
    
    public static func createResource<T : Decodable, ID>(
        _ type: T.Type,
        _ idType: ID.Type,
        path: String,
        restManager: RestManager
    ) -> RestResource<T, ID> {
        return RestResource(T.self, ID.self, path: path, restManager: restManager)
    }
    
}
