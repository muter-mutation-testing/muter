#if os(Linux)
import FoundationNetworking
#endif
import Foundation
@testable import muterCore

final class ServerSpy: Server {
    private(set) var urlPassed: URL?

    var dataToBeReturned: Data = .init()
    var urlResponseToBeReturned: URLResponse = URLResponse(url: URL(fileURLWithPath: ""), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    var errorToBeThrown: Error?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        urlPassed = url

        if let errorToBeThrown {
            throw errorToBeThrown
        }

        return (dataToBeReturned, urlResponseToBeReturned)
    }
}
