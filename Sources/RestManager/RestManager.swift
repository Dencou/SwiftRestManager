import RealHTTP
import AFNetworking

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
        
        let data: Data = rawResponse.body!.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        return Response<T>(
            body: try decoder.decode(_: T.self, from: data),
            status: rawResponse.status,
            headers: rawResponse.headers,
            url: rawResponse.url
        )
    }
    
    public func get<T : Decodable>(
        _ type: T.Type,
        path: String,
        method: String,
        queryParams: ParamMap? = nil
    ) async throws -> Response<T>  {
        return try await makeRequest(type, path: path, method: "GET")
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
            $0.method = .get
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
