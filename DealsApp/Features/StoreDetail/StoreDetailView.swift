import SwiftUI

struct StoreDetailView: View {
    @StateObject private var viewModel: StoreDetailViewModel
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var isSharing = false

    /// `store` must come from `CatalogService`, i.e. already validated.
    init(store: Store) {
        _viewModel = StateObject(wrappedValue: StoreDetailViewModel(store: store))
    }

    private var store: Store { viewModel.store }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StoreHeaderView(store: store)

                if !viewModel.availableActions.isEmpty {
                    StoreActionsView(viewModel: viewModel)
                }

                if let code = store.couponCode {
                    CouponCardView(viewModel: viewModel, code: code)
                }

                itemsSection
            }
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    isSharing = true
                } label: {
                    Label("store.share", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("store.share")

                favoriteButton
            }
        }
        .sheet(item: $viewModel.selectedItem) { item in
            ItemDetailSheet(item: item, store: store)
        }
        .sheet(isPresented: $isSharing) {
            ActivityView(items: [viewModel.shareText]) { completed in
                if completed { viewModel.didShare() }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            viewModel.onAppear()
            #if DEBUG
            if let id = UserDefaults.standard.string(forKey: "uiOpenItem"),
               let item = store.items.first(where: { $0.id == id }), viewModel.selectedItem == nil {
                viewModel.select(item)
            }
            #endif
        }
    }

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("store.items.title")
                .font(.title3.weight(.bold))
                .foregroundColor(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("store.vatNote")
                .font(.footnote)
                .foregroundColor(Theme.secondaryText)
            ForEach(store.items) { item in
                Button {
                    viewModel.select(item)
                } label: {
                    ItemRowView(item: item, store: store)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("item.\(item.id)")
            }
        }
        .padding(.horizontal, 16)
    }

    private var favoriteButton: some View {
        let isFavorite = favorites.isFavorite(store.id)
        return Button {
            viewModel.toggleFavorite(in: favorites)
        } label: {
            Label(LocalizedStringKey(isFavorite ? "store.favorite.remove" : "store.favorite.add"),
                  systemImage: isFavorite ? "heart.fill" : "heart")
                .foregroundColor(isFavorite ? .red : Theme.primary)
        }
        .accessibilityIdentifier("store.favorite")
    }
}
