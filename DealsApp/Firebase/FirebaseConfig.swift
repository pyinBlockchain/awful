import Foundation

/// Firebase project settings read from GoogleService-Info.plist.
///
/// We talk to Firebase over its REST APIs (no SDK) because the Firebase SDK needs a newer
/// Xcode than the dev Mac can run (CLAUDE.md §10, §12). Everything Firebase-specific stays
/// behind our own protocols so the SDK can replace this layer later (MIGRATION.md).
struct FirebaseConfig: Equatable {
    let apiKey: String
    let projectID: String
    let bundleID: String
    /// Firestore database name; the console's first database is "(default)".
    var databaseID: String = "(default)"

    enum LoadError: Error, Equatable {
        case fileMissing
        case keyMissing(String)
    }

    static func load(from bundle: Bundle = .main,
                     resource: String = "GoogleService-Info") throws -> FirebaseConfig {
        guard let url = bundle.url(forResource: resource, withExtension: "plist"),
              let plist = NSDictionary(contentsOf: url) as? [String: Any] else {
            throw LoadError.fileMissing
        }
        func value(_ key: String) throws -> String {
            guard let text = plist[key] as? String, !text.isEmpty else { throw LoadError.keyMissing(key) }
            return text
        }
        let config = FirebaseConfig(apiKey: try value("API_KEY"),
                                    projectID: try value("PROJECT_ID"),
                                    bundleID: try value("BUNDLE_ID"))
        #if DEBUG
        // Renaming the bundle ID (CLAUDE.md §1) means re-registering the app in Firebase
        // and replacing the plist; catch a stale plist early.
        if let running = Bundle.main.bundleIdentifier, running != config.bundleID,
           bundle == .main {
            DataWarningLog.warn("GoogleService-Info.plist is for \(config.bundleID), app is \(running)")
        }
        #endif
        return config
    }

    /// Firestore REST root, e.g. .../projects/<id>/databases/(default)/documents
    var firestoreDocumentsURL: URL {
        URL(string: "https://firestore.googleapis.com/v1/projects/\(projectID)/databases/\(databaseID)/documents")!
    }

    /// Firebase Auth (Identity Toolkit) REST root: accounts:signUp, accounts:signInWithPassword, …
    var identityToolkitURL: URL { URL(string: "https://identitytoolkit.googleapis.com/v1")! }

    /// Exchanges a refresh token for a fresh ID token.
    var secureTokenURL: URL { URL(string: "https://securetoken.googleapis.com/v1/token")! }
}
