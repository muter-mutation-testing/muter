import Foundation
import Version

protocol Server {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: Server {}

private let url = "https://api.github.com/repos/muter-mutation-testing/muter/releases?per_page=1"

struct UpdateCheck: RunCommandStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    @Dependency(\.server)
    private var server: Server

    private let currentVersion: Version

    init(currentVersion: Version? = Version(tolerant: version)) {
        self.currentVersion = currentVersion ?? .null
    }

    func run(
        with state: AnyRunCommandState
    ) async throws -> [RunCommandState.Change] {
        guard let releaseURL = URL(string: url) else {
            return []
        }

        notificationCenter.post(name: .updateCheckStarted, object: nil)

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
