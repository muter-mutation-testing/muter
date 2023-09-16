import Foundation
@testable import muterCore

final class ServerSpy: Server {
    private(set) var urlPassed: URL?

    var dataToBeReturned: Data = .init()
    var urlResponseToBeReturned: URLResponse = .init()
    var errorToBeThrown: Error?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        urlPassed = url

        if let errorToBeThrown {
            throw errorToBeThrown
        }

        return (dataToBeReturned, urlResponseToBeReturned)
    }
}
