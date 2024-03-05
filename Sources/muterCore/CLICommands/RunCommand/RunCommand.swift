import ArgumentParser
import Foundation

protocol RunCommand: AsyncParsableCommand {
    func run(with options: Run.Options) async throws
}

extension RunCommand {
    func run(with options: Run.Options) async throws {
        do {
            try await MutationTestHandler(options: options).run()
        } catch {
            print(
                """
                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  Muter has encountered an error  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️
                \(error)


                ⚠️ ⚠️ ⚠️ ⚠️ ⚠️  See the Muter error log above this line  ⚠️ ⚠️ ⚠️ ⚠️ ⚠️

                If you think this is a bug, or want help figuring out what could be happening, please open an issue at
                https://github.com/muter-mutation-testing/muter/issues
                """
            )

            Foundation.exit(-1)
        }
    }
}
