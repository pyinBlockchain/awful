# CLAUDE.md — Saudi Deals App (iOS, browse-only MVP)

Claude Code: read this whole file before any task. It is the source of truth for scope,
architecture, rules, and the build order. If a request conflicts with this file, ask first.

> **Section 12 (v2: merchant & admin accounts) extends v1 and overrides the v1 "no accounts /
> no backend" rules for merchants and admins only.** Customers stay anonymous.
>
> **Section 10 (Toolchain constraints) overrides any conflicting requirement below**
> (iOS 17, `@Observable`, SwiftData, `.xcstrings`, Swift 5.10+). Section 11 records accepted
> decisions that clarify the rules below.

---

## 1. What we are building

A native iOS app for Saudi Arabia where people **browse stores that have discounts** and
**see the discounted items inside each store**. Think Groupon's browsing experience, but:

- **NO payments, NO checkout, NO cart, NO vouchers sold in the app** (v1).
- **NO user accounts or login for customers.** Favorites are stored on the device only.
  (v2 adds accounts for merchants and admins only; see §12.)
- The user finds a deal in the app, then goes to the store (or the online store's website)
  and buys there.

Categories (v1):

| key            | Arabic (primary)   | English (secondary)       |
|----------------|--------------------|---------------------------|
| restaurants    | مطاعم              | Restaurants               |
| cafes          | مقاهي              | Cafés                     |
| hotels         | فنادق              | Hotels                    |
| beauty         | صالونات وسبا       | Salons & Spa              |
| retail         | متاجر              | Stores                    |
| online         | متاجر إلكترونية    | Online stores             |
| entertainment  | ترفيه وأنشطة       | Entertainment & Activities|

App display name is **not final yet**. Use the placeholder `DealsApp` and keep the display
name, bundle ID, and brand colors in ONE place (`project.yml` + `Theme.swift`) so renaming
takes minutes.

### Core business rule: discounts are 20%–50%
- Every discounted item must have `discountPercent` between **20 and 50 inclusive**.
- `discountPercent` is **computed**, never typed in by hand:
  `round((originalPrice - discountedPrice) / originalPrice * 100)`.
- Items outside 20–50, with `discountedPrice >= originalPrice`, or expired (`validUntil` in
  the past) are **excluded** from the UI and logged as a data warning (DEBUG builds only).
- A store's headline badge = the **highest** valid item discount: "خصم حتى 50%".
- A store with zero valid items is hidden.
- All prices are **VAT-inclusive** (Saudi rule for displayed consumer prices). Show the note
  "الأسعار شاملة ضريبة القيمة المضافة" on the store screen.

---

## 2. Screens and behavior

### Tab bar (3 tabs)
1. **الرئيسية / Home**
2. **الخريطة / Map**
3. **المفضلة / Favorites**

### Home
- Search bar, placeholder: "ابحث عن متجر أو عرض".
- Horizontal category chips (plus "الكل" / All).
- Discount filter chips: "الكل", "20% فأكثر", "30% فأكثر", "40% فأكثر", "50%".
  Filtering uses the store's max valid discount.
- Sort menu: "الأعلى خصمًا" (highest discount, default), "الأقرب" (nearest; only when location
  permission is granted), "الأحدث" (newest offers).
- City picker in the navigation bar (seed data: Riyadh; keep structure ready for Jeddah and
  Dammam/Khobar).
- Store list: each row/card shows logo (or generated initials placeholder), store name,
  category, district, distance (if available), and the discount badge.
- Empty state: "لا توجد عروض تطابق بحثك. جرّب نسبة خصم أقل أو تصنيفًا آخر." with a
  "مسح الفلاتر" (Clear filters) button.

### Store detail (tap a store)
- Header: cover image/placeholder, logo, name, category, district, max discount badge,
  optional "مرخّص" badge when `discountPermitNumber` exists.
- Action buttons (show only the ones with data):
  "اتصال" (tel:), "واتساب" (wa.me link), "الاتجاهات" (Apple Maps), "زيارة الموقع" (website).
- For **online** stores: show `couponCode` with a "نسخ الكود" (Copy code) button and a
  confirmation "تم نسخ الكود".
- **Discounted items list**, sorted by highest discount first. Each item shows:
  image/placeholder, name, original price struck through, discounted price, percent badge,
  and "ساري حتى <date>" (valid until). Show the date in Gregorian, with the Hijri date as a
  secondary line.
- Tapping an item opens an item detail sheet (bigger image, description, terms/conditions).
- Share button (ShareLink) for the store.
- Favorite (heart) button for the store.

### Map
- MapKit map of stores in the selected city with pins showing the max discount (e.g. "40%").
- Same category and discount filters as Home.
- Tapping a pin shows a compact card; tapping the card opens Store detail.
- Online-only stores do not appear on the map.

### Favorites
- List of favorited stores (stored locally with SwiftData or UserDefaults; no account).
- Empty state: "لم تضف أي متجر للمفضلة بعد." with a button to go to Home.

---

## 3. Arabic-first requirements (mandatory)

- **Development language: Arabic.** Supported: `ar` (default), `en`.
- All user-facing strings live in a String Catalog (`Localizable.xcstrings`). **No hard-coded
  UI strings in views.**
- **RTL correctness:** use `leading`/`trailing`, never `left`/`right`. Directional SF Symbols
  must mirror. Verify every screen in Arabic AND English.
- Font: system font (SF Arabic renders automatically). Support Dynamic Type.
- Numbers: Western digits (0–9) by default for prices and percentages. Keep this configurable
  in one formatter.
- Currency: format as "120 ر.س" in Arabic, "SAR 120" in English, via ONE shared
  `PriceFormatter`.
- Dates: Gregorian primary, Hijri (Umm al-Qura calendar) secondary.
- **Arabic-aware search** (`ArabicSearchNormalizer`), applied to both query and data:
  - remove diacritics (tashkeel) and tatweel (ـ)
  - أ إ آ ٱ → ا ; ى → ي ; ة → ه ; ؤ → و ; ئ → ي
  - lowercase English, trim and collapse spaces
  - match against store name (ar + en), item names (ar + en), category, and `tags`.

---

## 4. Architecture

- **SwiftUI**, iOS 17.0 minimum, Swift 5.10+ (Swift 6 strict concurrency if it builds cleanly).
- **MVVM** with the `@Observable` macro. Views stay thin; logic goes in view models and services.
- **No third-party dependencies in v1.** Ask before adding any. (v2: Firebase approved, used via
  its REST APIs with no SDK for now; see §12.)
- Project generated with **XcodeGen** (`project.yml`) so everything works from the terminal.

### Data layer (swappable by design)
```swift
protocol CatalogRepository {
    func fetchCatalog(city: String) async throws -> Catalog
}
```
- Phase 1: `BundledJSONCatalogRepository` reads `Resources/SeedData/catalog.json`.
- Phase 4: `RemoteJSONCatalogRepository` downloads the same JSON format from a URL (set in
  one config constant), caches the last good copy on disk, and falls back to the bundled file
  when offline. This lets us update deals **without an App Store release and without a
  backend**.
- v2 adds a merchant portal on Firebase (§12). Still no custom backend server.

### Data model (JSON and Swift `Codable`)
```json
{
  "version": 1,
  "updatedAt": "2026-09-23T00:00:00Z",
  "stores": [
    {
      "id": "st_001",
      "name": { "ar": "مطعم النخلة", "en": "Al Nakhla Restaurant" },
      "category": "restaurants",
      "type": "physical",
      "city": "riyadh",
      "district": { "ar": "حي الملقا", "en": "Al Malqa" },
      "latitude": 24.8105,
      "longitude": 46.6120,
      "phone": "+966500000000",
      "whatsapp": "+966500000000",
      "website": null,
      "couponCode": null,
      "logoURL": null,
      "coverURL": null,
      "discountPermitNumber": null,
      "tags": ["مشويات", "grill", "عائلي"],
      "items": [
        {
          "id": "it_001",
          "name": { "ar": "وجبة مشويات عائلية", "en": "Family grill platter" },
          "description": { "ar": "تكفي 4 أشخاص", "en": "Serves 4" },
          "originalPrice": 200,
          "discountedPrice": 140,
          "validFrom": "2026-09-01",
          "validUntil": "2026-10-31",
          "terms": { "ar": "داخل المطعم فقط", "en": "Dine-in only" },
          "imageURL": null
        }
      ]
    }
  ]
}
```
- `type`: `physical` | `online` | `hotel`.
- Images are optional. When missing, render a colored placeholder with the store's initials
  or a category SF Symbol. **Never** use real brand logos or scraped images.
- `discountPercent`, `isValid`, and `maxDiscount` are computed properties, not stored fields.

### Services
- `DiscountCalculator`: percent calc and the 20–50 / expiry / price-sanity validation.
- `ArabicSearchNormalizer`: see section 3.
- `LocationService`: CoreLocation wrapper. The app works fully without permission;
  permission prompt text (Arabic):
  "نستخدم موقعك لعرض أقرب العروض إليك فقط."
- `FavoritesStore`: local persistence.
- `AnalyticsService` (protocol): logs events. v1 implementation prints in DEBUG only. Events:
  `store_viewed`, `item_viewed`, `filter_used`, `search_performed`, `call_tapped`,
  `whatsapp_tapped`, `directions_tapped`, `website_tapped`, `coupon_copied`,
  `store_favorited`, `store_shared`. These events are how we measure merchant value later, so
  wire them in every relevant action. No personal data in events.

### Folder structure
```
DealsApp/
  project.yml
  CLAUDE.md
  DealsApp/
    App/            (DealsApp.swift, RootTabView.swift, AppConfig.swift)
    Models/         (Store.swift, Item.swift, Catalog.swift, Category.swift, LocalizedText.swift)
    Data/           (CatalogRepository.swift, BundledJSONCatalogRepository.swift, RemoteJSONCatalogRepository.swift)
    Services/       (DiscountCalculator, ArabicSearchNormalizer, LocationService, FavoritesStore, AnalyticsService, PriceFormatter, DateFormatterService)
    Features/
      Home/         (HomeView, HomeViewModel, StoreCardView, FilterBarView)
      StoreDetail/  (StoreDetailView, StoreDetailViewModel, ItemRowView, ItemDetailSheet)
      Map/          (MapScreen, MapViewModel)
      Favorites/    (FavoritesView, FavoritesViewModel)
    DesignSystem/   (Theme.swift, DiscountBadge.swift, PlaceholderImage.swift, EmptyStateView.swift)
    Resources/      (Localizable.xcstrings, Assets.xcassets, SeedData/catalog.json)
  DealsAppTests/
  DealsAppUITests/
```

---

## 5. Design direction

- The one bold element is the **discount badge**. Everything else stays calm and clean so
  the percentages stand out.
- Starting palette (all colors in `Theme.swift`, light and dark variants):
  - Ink (text): `#1A2233`
  - Primary (palm green): `#0F6B4F`
  - Deal accent (saffron, discount badges only): `#F2A900` with ink text
  - Surface (sand): `#F3EEE6`
  - Background: `#FFFFFF`; dark mode uses deep ink backgrounds
- Real Arabic copy everywhere; no lorem ipsum. Sentence case in English. Buttons say exactly
  what happens ("اتصال", "نسخ الكود").
- Accessibility: VoiceOver labels on badges (e.g. "خصم 40 بالمئة"), 44pt tap targets,
  Dynamic Type, sufficient contrast, respect Reduce Motion.

---

## 6. Seed data (Phase 1)

Create `catalog.json` with **20 fictional stores in Riyadh** (no real brand names), spread
across all 7 categories, each with 3–6 items. Use realistic Riyadh districts and coordinates,
realistic SAR prices, discounts spread across 20–50%. Include at least 2 online stores with
coupon codes and 2 hotels. For testing the validation rules, also include:
- 2 items with discounts outside 20–50% (must be hidden),
- 2 expired items (must be hidden),
- 1 store whose items are all invalid (store must be hidden).

---

## 7. Build phases (do them in order; stop and report after each)

**Phase 0: Project setup**
- `brew install xcodegen` if missing. Create `project.yml`, generate the project, confirm it
  builds. Initialize git with a Swift `.gitignore`. Commit.

**Phase 1: Models, data, core services + unit tests**
- Models, JSON decoding, seed data, `DiscountCalculator`, `ArabicSearchNormalizer`,
  `PriceFormatter`. Unit tests for: percent calculation and rounding, 20–50 boundaries
  (19, 20, 50, 51), expiry, hidden stores, Arabic normalization cases, price formatting in
  ar and en. All tests pass. Commit.

**Phase 2: Home + Store detail**
- Full Home screen (search, categories, discount filter, sort, empty state) and Store detail
  (actions, items, item sheet, coupon copy, share). String Catalog in ar + en. Commit.

**Phase 3: Map + Favorites + Location**
- Map with discount pins and filters, Favorites persistence, distance sorting. Commit.

**Phase 4: Remote JSON + polish**
- `RemoteJSONCatalogRepository` with caching and offline fallback, pull-to-refresh, loading
  and error states in Arabic, analytics events wired everywhere, accessibility pass,
  dark mode check. Commit.

**Phase 5: QA**
- UI tests: launch in Arabic, filter to 40%+, open a store, verify only valid items appear,
  copy a coupon, favorite a store. Run in both `ar` and `en`. Fix every RTL issue found.
  Commit and write a short `RELEASE_NOTES.md`.

### Definition of done for every phase
- Builds with zero warnings you introduced, all tests pass, no hard-coded UI strings, works
  in Arabic (RTL) and English, committed with a clear message.

---

## 8. Commands

```bash
# pick an available simulator first
xcrun simctl list devices available

xcodegen generate
xcodebuild -scheme DealsApp \
  -destination 'platform=iOS Simulator,name=<SIMULATOR_NAME>' build
xcodebuild -scheme DealsApp \
  -destination 'platform=iOS Simulator,name=<SIMULATOR_NAME>' test

# run the UI tests in Arabic
xcodebuild -scheme DealsApp \
  -destination 'platform=iOS Simulator,name=<SIMULATOR_NAME>' \
  test -testLanguage ar -testRegion SA
```

**On this machine, use the wrapper** (it strips conda's `LD`/`CC`/`SDKROOT`/… env vars, which
otherwise make xcodebuild link with the wrong `ld`; defaults to iPhone 14 / iOS 16.2):

```bash
xcodegen generate
scripts/xcb.sh build
scripts/xcb.sh test
scripts/xcb.sh test -testLanguage ar -testRegion SA
# UI tests run every flow in both Arabic and English by default. With -testLanguage, the other
# language's tests are skipped (xcodebuild forces that language on every app launch).
# If a build ever links with /opt/anaconda3/.../ld, the env leaked into cached build data:
rm -rf build && scripts/xcb.sh build
```

---

## 9. Rules for Claude Code

- **Never add** payments, cart, checkout, customer login/accounts, or a custom backend server.
  Merchant/admin accounts on Firebase are allowed (§12).
  If a task seems to need one, stop and ask.
- Never add third-party packages without asking.
- Never hard-code UI strings; always use the String Catalog with ar and en values.
- Never use `left`/`right` layout; always `leading`/`trailing`.
- Never store the discount percent in data; always compute it.
- Keep files small (roughly under 250 lines); split views into subviews.
- Write comments explaining **why**, not what.
- After each phase: run build + tests, then summarize what was done, what is left, and any
  decision taken (one line each) for the decision log.
- If something in this file is unclear or looks wrong, say so before building around it.

---

## 10. Toolchain constraints (current dev machine)

The dev machine is a MacBook Pro 2015 capped at macOS 12.7 → **Xcode 14.2, Swift 5.7,
iOS 16.2 SDK**. Until we move to Xcode 16+ (see `MIGRATION.md`), these override sections 3–4:

- Deployment target: **iOS 16.0**. Test simulator: iPhone 14 (iOS 16.2).
- **Swift 5 language mode.** No Swift 5.9+ features: no macros (`@Observable`, `#Preview`,
  `#Predicate`), no `if`/`switch` expressions, no parameter packs, no `consume`/`borrowing`.
- State: `ObservableObject` + `@Published` + `@StateObject`/`@ObservedObject`/`@EnvironmentObject`.
- Strings: `ar.lproj/Localizable.strings` and `en.lproj/Localizable.strings` (not `.xcstrings`).
  Every key must exist in both files.
- Favorites persistence: `UserDefaults` (no SwiftData).
- No iOS 17-only APIs (e.g. new `Map` content builder, `MapCameraPosition`, `.onChange` two-param
  closure, `ContentUnavailableView`, `TipKit`). Use iOS 16 equivalents.
- XcodeGen is installed from the GitHub release binary (`/usr/local/bin/xcodegen`), because
  Homebrew cannot build it on macOS 12.
- App Store submission needs a newer Xcode; build releases on a newer Mac / Xcode Cloud / CI.
- **Firebase SDK can't be used** (it needs Xcode 15+/26.2). Use Firebase REST APIs behind our
  protocols until the move to a newer Mac (§12, MIGRATION.md §7).
- Bundle ID placeholder: **`sa.dealsapp.ios`**, defined once in `project.yml`.
- Git: commit locally after each phase. **Do not push** until the user says so.

## 11. Decision log (accepted clarifications)

1. **Discount validation uses the EXACT percent**: valid iff `20.0 <= exact <= 50.0`.
   **Displayed percent is rounded DOWN (floor)** so we never overstate a discount (Saudi
   advertising accuracy). 19.5% → rejected; 20.4% → shows 20%; 49.9% → shows 49%; 50.0% → 50%.
   Calculations use integer halalas to avoid floating-point drift at the boundaries.
   `maxDiscount` and the filter chips use the displayed (floored) percent.
2. **Expiry**: an item is valid through the **end of its `validUntil` day, Asia/Riyadh time**.
3. **Not-yet-started items** (`validFrom` in the future, Riyadh time) are hidden, like expired ones.
4. **"الأحدث" (newest) sort** = the latest `validFrom` among a store's valid items.
5. **Seed data**: 20 visible stores + 1 intentionally all-invalid store (21 in the file).
   Valid seed items use `validUntil` 2027-12-31 or later; intentionally expired items use 2025 dates.
6. Tests never depend on the real clock; validation takes an injected `now`.
7. **`type` vs `category`** are independent fields; a mismatch (e.g. `online` type in a physical
   category, or an `online`-type store that has no website) logs a DEBUG data warning only.
   Latitude/longitude are optional (online stores have none).
8. The repo root (`Tawfirapp/`) plays the role of the top-level `DealsApp/` folder in section 4.
9. **Prices**: whole amounts show no decimals ("120 ر.س"); others show 2 decimals ("12.50 ر.س").
10. `AnalyticsService` protocol + DEBUG console stub are part of Phase 1.
11. **Search**: multi-word queries match when EVERY word appears in some searchable field.
    The normalizer also maps Arabic-Indic/Persian digits to 0–9 and strips LRM/RLM/zero-width
    marks (common in pasted Arabic). Latin accents fold ("Café" → "cafe").
12. **Lossy decoding**: a malformed store or item is skipped (DEBUG warning), not fatal, so one
    typo in remote JSON can't blank the app.
13. **`search_performed`** logs only `query_length` and `result_count`, never the query text
    (no-personal-data rule). Revisit if merchants need search-term insights.
14. Validation (`CatalogValidator`) is a separate step from fetching: repositories return raw
    data; the UI layer must validate before display. Item ties sort by `id` for stable order.
15. **Validated-only UI**: `CatalogService` is the single source of stores for every screen; it
    publishes only `CatalogValidator` output and re-validates when the app returns to foreground.
16. **Percent display**: in Arabic, percents are wrapped in a bidi isolate so they always read
    "50%" (never "%50"), matching the chips.
17. **Arabic dates** use `d MMMM y` ("31 ديسمبر 2027", Hijri "3 شعبان 1449 هـ"); iOS's Arabic long
    style inserts a comma that Saudi usage omits.
18. **RTL chip rows**: iOS 16 horizontal ScrollViews open at the wrong end in RTL; FilterBarView runs
    the scroll view LTR and starts at the right edge. Remove the workaround after moving to iOS 17+.
19. **Logo initials**: Arabic uses one letter, skipping generic words (مطعم، متجر، مقهى…) and "ال".
20. **DEBUG launch args** (`-uiQuery`, `-uiMinDiscount`, `-uiOpenStore`) put Home in a known state for
    screenshots/QA; compiled out of release builds.
21. `FavoritesStore` (UserDefaults) landed in Phase 2 because Store detail needs the heart button;
    the Favorites tab list is still Phase 3.
22. **Shared filters**: category + discount filters (`StoreFilters`) are shared by Home and Map;
    search and sort are Home-only.
23. **Location permission is asked only on user action** (map "موقعي" button, or "تفعيل الموقع
    لعرض الأقرب" in the sort menu), never at launch. "الأقرب" appears once a location is known;
    without one it falls back to highest discount. Online stores sort last by distance.
24. **Distances**: under 1 km rounded to 10 m ("850 م"); 1–10 km one decimal ("2.4 كم"); above that
    whole km. Same digit setting as prices.
25. **Favorites** resolve through `CatalogService` (validated only), sorted by highest discount. A
    favorite with no valid deals right now is hidden but stays saved. Removal = long-press menu or
    VoiceOver action (no `List` swipe: iOS 16 renders swiped List rows mirrored in RTL).
26. **Map (iOS 16)**: no pin clustering and no way to bring the selected pin to the front; the card
    shows the selection. Revisit with iOS 17 `Map` + clustering (see MIGRATION.md). The card sits
    above the Apple Maps legal link, which must stay visible.
27. **Remote catalog**: `AppConfig.remoteCatalogURL` is `nil` until the JSON is hosted (https);
    while nil the app uses the bundled seed only. Remote fetch → cache last good copy (only if it
    decodes, version == 1, and has stores) → on failure use the newer of cache vs bundled seed.
    Refetch on foreground when older than 1 h, and on pull-to-refresh. A failed refresh keeps the
    current list. An "offline" banner shows only when a remote is configured but not served.
28. **Share** uses `UIActivityViewController` (not `ShareLink`) so `store_shared` logs only completed
    shares; `store_viewed` logs once per visit; city changes log `filter_used` (filter=city).
29. **Contrast**: all text/background pairs are ≥ 4.5:1 in light and dark (unit-tested).
    Text on primary uses `onPrimary` (white in light, deep ink in dark).
30. **Dynamic Type (accessibility sizes)**: decorative logos/item images are hidden, action buttons
    stack vertically with icon beside label, prices stack, badges may wrap (never truncate).
31. **UI tests**: one shared set of flows runs as `ArabicFlowTests` and `EnglishFlowTests`, each
    launching the app in its language with `-uiTestingReset YES` (DEBUG-only: clears favorites).
    Under `-testLanguage xx` the other language's tests skip rather than fail.

---

## 12. v2: Merchant & admin accounts (Firebase)

Extends everything above; nothing in the customer experience changes except that live data
comes from Firestore. **Customers stay anonymous.**

### Roles
| Role | How | Can |
|---|---|---|
| Customer | not signed in | read approved, valid content only |
| Seller | signs up with email/password → `sellerStatus: "pending"` | once `approved`: submit their ONE store and its items for review |
| Admin | `role: "admin"` set by hand in the Firebase console | approve/reject sellers and submissions, suspend (ban) sellers |

Roles live in Firestore `users/{uid}` docs (not custom claims, which need Cloud Functions).
**No admin email or UID is ever hard-coded in the app.**

Seller statuses: `pending` → `approved` | `rejected`; `approved` ↔ `suspended` (ban, reversible).
Content statuses: `pending_review` | `approved` | `rejected` (+ `rejectionReason`), plus
`suspended` when the owner is banned.

### Data flow (decided; details finalized in F1)
- **Sellers never write customer-visible documents.** They write to `submissions`; an admin
  approval copies the submission into the public `stores` / `items` documents. The live version
  stays visible while an edit is under review. Store-profile edits are reviewed too (coupon codes,
  phone numbers, and permit numbers are claims customers rely on).
- Store and Item gain `ownerId`, `status`, `reviewedBy`, `reviewedAt`, `isDemoData`. **Every v1
  field and validation rule is unchanged** (computed 20–50% discount, VAT-inclusive prices,
  expiry in Riyadh days).
- Customer reads ask Firestore only for `status == "approved"`, then **still run
  `CatalogValidator`**: never trust the backend alone.
- Data source chain for customers: **Firestore → last good copy on disk → bundled seed JSON
  (DEBUG builds only)**. Release builds never show the fictional seed stores.
- Demo content: the 20 valid seed stores (not the test fixtures, not `st_021`) are imported into
  Firestore as `approved` with `isDemoData: true`, **without phone or WhatsApp** (the seed numbers
  look like real Saudi mobiles). The app shows a "عرض توضيحي / Demo" label on them.
- One store per seller. No image upload yet (placeholders stay). Store location is set with a map
  pin or "use my location"; online stores have none.

### Implementation: REST now, SDK later
- Xcode 14.2 can't build the Firebase SDK (11.x+ needs Xcode 15+; 12.x needs Xcode 26.2), so we
  call **Firebase Auth (Identity Toolkit) and Firestore over their REST APIs** with `URLSession`.
  Security Rules apply exactly the same (requests carry the user's ID token).
- Everything sits behind our own protocols (`CatalogRepository` and its siblings for auth,
  seller, and admin work). Screens and view models never see REST types, so moving to the SDK
  (MIGRATION.md §7) replaces implementations only.
- `FirebaseConfig` reads `GoogleService-Info.plist` (committed: it isn't secret; the rules are the
  security). The database is Firestore Standard, `(default)`, in `me-central2` (Dammam).
- Firebase error codes are mapped to our own Arabic/English strings; raw Firebase messages are
  never shown.

### App Store & privacy
- Sellers can delete their account in-app (guideline 5.1.1(v)).
- Update App Privacy labels (email address, user ID) and provide a privacy policy URL.
- Admins approve only sellers with a verified email.

### Entry point
A small ⓘ button in the Home toolbar opens "حول التطبيق / About" (version, privacy link,
"للتجار / For merchants"). Merchant sign-in lives there; signed-in admins see the admin screens
instead of the store editor. The customer tab bar is unchanged.

### v2 phases (stop and report after each)
- **F0** Toolchain decision (REST), CLAUDE.md/MIGRATION.md, Firebase config. ✅
- **F1** Data model + Firestore layout + `firestore.rules` + rules tests (emulator) + §13 below.
- **F2** Customer read path: Firestore repository + validator + fallback chain + demo import.
- **F3** Merchant auth: About screen, sign-up/in, password reset, sign-out, delete account.
- **F4** Seller editor: my store, items, submissions with "قيد المراجعة / Under review".
- **F5** Admin: sellers queue, items queue (reject with reason), suspend/unsuspend.
- **F6** QA: rules tests in CI, UI tests ar/en, RTL/dark/Dynamic Type, release notes.
- **Manual step after F5 (owner):** set `role: "admin"` on your own `users` doc in the console.

## 13. Firestore Security Rules

*Written in F1: what each rule blocks and why.*
