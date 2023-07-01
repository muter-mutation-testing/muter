import Foundation
import Version

typealias MuterVersionFecher = (URL, Data.ReadingOptions) throws -> Data

private let url = "https://api.github.com/repos/muter-mutation-testing/muter/releases?per_page=1"

struct UpdateCheck: RunCommandStep {
    @Dependency(\.notificationCenter)
    private var notificationCenter: NotificationCenter
    private let versionFetcher: MuterVersionFecher
    private let currentVersion: Version

    init(
        versionFetcher: @escaping MuterVersionFecher = Data.init(contentsOf:options:),
        currentVersion: Version = Version(tolerant: version)!
    ) {
        self.versionFetcher = versionFetcher
        self.currentVersion = currentVersion
    }

    func run(with state: AnyRunCommandState) -> Result<[RunCommandState.Change], MuterError> {
        guard let releaseURL = URL(string: url) else {
            return .success([])
        }

        notificationCenter.post(name: .updateCheckStarted, object: nil)

        var newVersion: String?

        do {
            let data = try versionFetcher(releaseURL, [])
            let latestVersion = try muterLatestVersion(data)

            if currentVersion < latestVersion {
                newVersion = latestVersion.description
            }
        } catch {}

        notificationCenter.post(name: .updateCheckFinished, object: newVersion)

        return .success([])
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
