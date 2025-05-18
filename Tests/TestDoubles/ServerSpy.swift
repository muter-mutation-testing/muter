import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import muterCore

final class ServerSpy: Server {
    private(set) var urlPassed: URL?

    var dataToBeReturned: Data = .init()
    var urlResponseToBeReturned: URLResponse = .init(
        url: URL(fileURLWithPath: ""),
        mimeType: nil,
        expectedContentLength: 0,
        textEncodingName: nil
    )
    var errorToBeThrown: Error?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        urlPassed = url

        if let errorToBeThrown {
            throw errorToBeThrown
        }

        return (dataToBeReturned, urlResponseToBeReturned)
    }
}
