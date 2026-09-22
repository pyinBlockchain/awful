import Foundation

/// Shared services that view models take as default arguments, so tests can inject fakes
/// without a DI framework.
enum AppDependencies {
    static let analytics: AnalyticsService = ConsoleAnalyticsService()
}
