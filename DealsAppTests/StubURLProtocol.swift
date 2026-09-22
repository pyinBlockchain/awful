import Foundation
@testable import DealsApp

/// Serves canned HTTP responses so repository tests never touch the network.
final class StubURLProtocol: URLProtocol {
    enum Reply {
        case response(status: Int, body: Data)
        case failure(URLError.Code)
    }

    static var reply: Reply = .failure(.notConnectedToInternet)
    static var requestCount = 0

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        switch Self.reply {
        case let .response(status, body):
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }

    override func stopLoading() {}
}

final class InMemoryCatalogCache: CatalogCaching {
    var data: Data?
    init(_ data: Data? = nil) { self.data = data }
    func load() -> Data? { data }
    func save(_ data: Data) throws { self.data = data }
}
