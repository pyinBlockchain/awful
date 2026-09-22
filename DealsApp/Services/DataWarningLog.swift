import Foundation
import os

/// Data problems are for us, not for users: log them in DEBUG and stay silent in release.
enum DataWarningLog {
    #if DEBUG
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DealsApp",
                                       category: "data")
    #endif

    static func warn(_ message: String) {
        #if DEBUG
        logger.warning("\(message, privacy: .public)")
        #endif
    }
}
