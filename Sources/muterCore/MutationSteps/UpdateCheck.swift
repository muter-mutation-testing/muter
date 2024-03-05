#if os(Linux)
import FoundationNetworking
#endif
import Foundation
import Version

protocol Server {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

#if os(Linux)
extension URLSession: Server {
    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            dataTask(with: url) { data, urlResponse, error in
                if let data, let urlResponse {
                    continuation.resume(returning: (data, urlResponse))
                } else if let error {
                    continuation.resume(throwing: error)
                }

            }.resume()
        }
    }
}
#else
extension URLSession: Server {}
#endif

private let url = "https://api.github.com/repos/muter-mutation-testing/muter/releases?per_page=1"

struct UpdateCheck: MutationStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.server)
    private var server: Server

    private let currentVersion: Version

    init(currentVersion: Version? = Version(tolerant: version)) {
        self.currentVersion = currentVersion ?? .null
    }

    func run(
        with state: AnyMutationTestState
    ) async throws -> [MutationTestState.Change] {
        guard let releaseURL = URL(string: url) else {
            return []
        }

        notificationCenter.post(name: .updateCheckStarted, object: nil)

        do {
            let (data, _) = try await server.data(from: releaseURL)

            guard let newVersion = try? muterLatestVersion(data),
                  currentVersion < newVersion
            else {
                notificationCenter.post(name: .updateCheckFinished, object: nil)
                return []
            }

            let latestVersion = newVersion.description

            notificationCenter.post(name: .updateCheckFinished, object: latestVersion)

            return [
                .newVersionAvaiable(latestVersion)
            ]
        } catch {
            notificationCenter.post(name: .updateCheckFinished, object: nil)
            return []
        }
    }

    private func muterLatestVersion(_ data: Data) throws -> Version {
        guard let release = try? JSONDecoder().decode([MuterVersion].self, from: data),
              let muterVersion = release.first,
              let latestVersion = Version(tolerant: muterVersion.number)
        else {
            throw UpdateCheckError.parsingError
        }

        return latestVersion
    }
}

private enum UpdateCheckError: Error {
    case parsingError
}

struct MuterVersion: Decodable {
    let number: String

    private enum CodingKeys: String, CodingKey {
        case number = "tag_name"
    }
}
