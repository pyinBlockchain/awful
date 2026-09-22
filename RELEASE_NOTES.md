# DealsApp v0.1.0 — browse-only MVP (internal)

*Placeholder name. Built with Xcode 14.2 for iOS 16+. Not yet submitted.*

## What's in it
- **Home**: Arabic-first deals list for Riyadh with Arabic-aware search, 7 category chips,
  discount chips (20%+ … 50%), and sorting by highest discount, newest, or nearest.
- **Store detail**: call, WhatsApp, directions, and website actions (shown only when the store
  has them), coupon codes with one-tap copy for online stores, discounted items with Gregorian
  and Hijri validity dates, item details and terms, share, and favorite.
- **Map**: discount pins for physical stores, shared filters with Home, "my location".
- **Favorites**: saved on the device only (no accounts).
- **Arabic and English**, full RTL support, dark mode, Dynamic Type up to the largest
  accessibility sizes, VoiceOver labels for discounts and prices.
- **Deals update without an App Store release** once a remote catalog URL is set: the app
  caches the last good copy and works offline.

## Rules enforced
- Only discounts from 20% to 50% (checked on the exact value) are shown; percentages are rounded
  down so a discount is never overstated. Expired or not-yet-started offers are hidden, and
  stores with no valid offers are hidden. All prices shown include VAT.

## Quality
- 107 unit tests, and 15 UI tests covering Arabic and English: launch direction, 40%+ filter,
  valid-items-only, hidden invalid store, coupon copy, favorites, Arabic spelling-tolerant search.
- WCAG AA contrast checked by unit tests in light and dark mode.

## Known limitations
- The remote catalog URL isn't set yet; the app uses the 21-store Riyadh seed data.
- Riyadh only (Jeddah and Dammam/Khobar are ready in code but have no data).
- Map pins can overlap in dense areas (no clustering on iOS 16).
- No payments, cart, accounts, or backend by design (v1 scope).
- App Store submission requires a newer Xcode than the dev Mac supports — see `MIGRATION.md`.
- The app name, bundle ID (`sa.dealsapp.ios`), and icon are placeholders.
