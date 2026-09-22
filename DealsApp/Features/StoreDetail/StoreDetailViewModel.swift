import Foundation
import UIKit

enum StoreAction: String, CaseIterable, Identifiable {
    case call, whatsapp, directions, website

    var id: String { rawValue }
    var titleKey: String { "store.action.\(rawValue)" }

    var symbolName: String {
        switch self {
        case .call: return "phone.fill"
        case .whatsapp: return "message.fill"
        case .directions: return "arrow.triangle.turn.up.right.diamond.fill"
        case .website: return "safari.fill"
        }
    }
}

@MainActor
final class StoreDetailViewModel: ObservableObject {
    let store: Store
    @Published var selectedItem: Item?
    @Published private(set) var couponCopied = false

    private let analytics: AnalyticsService
    private let copyToPasteboard: (String) -> Void
    private var copyResetTask: Task<Void, Never>?
    private var hasLoggedView = false

    init(store: Store,
         analytics: AnalyticsService = AppDependencies.analytics,
         copyToPasteboard: @escaping (String) -> Void = { UIPasteboard.general.string = $0 }) {
        self.store = store
        self.analytics = analytics
        self.copyToPasteboard = copyToPasteboard
    }

    /// Only actions backed by data are shown (CLAUDE.md §2).
    var availableActions: [StoreAction] {
        StoreAction.allCases.filter { url(for: $0) != nil }
    }

    func url(for action: StoreAction) -> URL? {
        switch action {
        case .call:
            return store.phone.flatMap { URL(string: "tel:\(Self.dialable($0))") }
        case .whatsapp:
            // wa.me wants the international number as digits only, no "+".
            return store.whatsapp.flatMap { URL(string: "https://wa.me/\(Self.digits($0))") }
        case .directions:
            guard let lat = store.latitude, let lon = store.longitude else { return nil }
            return URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d")
        case .website:
            return store.website
        }
    }

    /// `onAppear` fires again after switching tabs and back; count one view per visit.
    func onAppear() {
        guard !hasLoggedView else { return }
        hasLoggedView = true
        analytics.log(.storeViewed(storeID: store.id))
    }

    func didPerform(_ action: StoreAction) {
        switch action {
        case .call: analytics.log(.callTapped(storeID: store.id))
        case .whatsapp: analytics.log(.whatsappTapped(storeID: store.id))
        case .directions: analytics.log(.directionsTapped(storeID: store.id))
        case .website: analytics.log(.websiteTapped(storeID: store.id))
        }
    }

    func select(_ item: Item) {
        selectedItem = item
        analytics.log(.itemViewed(storeID: store.id, itemID: item.id))
    }

    func copyCoupon() {
        guard let code = store.couponCode else { return }
        copyToPasteboard(code)
        couponCopied = true
        analytics.log(.couponCopied(storeID: store.id))
        copyResetTask?.cancel()
        copyResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.couponCopied = false
        }
    }

    func toggleFavorite(in favorites: FavoritesStore) {
        let isFavorite = favorites.toggle(store.id)
        analytics.log(.storeFavorited(storeID: store.id, isFavorite: isFavorite))
    }

    func didShare() {
        analytics.log(.storeShared(storeID: store.id))
    }

    /// "مطعم النخلة — خصم حتى 50%" plus the website when there is one.
    var shareText: String {
        let percent = PriceFormatter().percent(store.maxDiscount ?? 0)
        var text = L10n.tr("store.share.message", store.name.resolved(), percent)
        if let website = store.website {
            text += "\n\(website.absoluteString)"
        }
        return text
    }

    private static func digits(_ phone: String) -> String {
        phone.filter(\.isASCII).filter(\.isNumber)
    }

    private static func dialable(_ phone: String) -> String {
        (phone.hasPrefix("+") ? "+" : "") + digits(phone)
    }
}
