import Foundation

/// Formatted strings for the running UI language. Static keys can go straight into
/// `Text("key")`; use this when a value has to be substituted in.
enum L10n {
    static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return args.isEmpty ? format : String(format: format, arguments: args)
    }
}
