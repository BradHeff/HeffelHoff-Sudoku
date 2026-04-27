# Monetization setup

The in-app UX for purchasing extra lives + hints and watching rewarded ads is **already wired** behind a `MonetizationService` abstraction (`lib/features/monetization/data/monetization_service.dart`). The shipping default is a `MockMonetizationService` that always succeeds after a short delay so the flows are testable end-to-end without any external setup.

To take real money you replace the mock with the real Apple / Google plumbing. The work splits into four independent tracks:

---

## 1. Apple App Store (iOS)

### Account

- **Apple Developer Program** — $99 / year. Sign up at https://developer.apple.com.
- After approval (1–2 days), open **App Store Connect** → My Apps → **+** → New App. Bundle id = `com.heffelhoff.heffelhoff_sudoku` (already set in the Flutter project).

### In-app products

App Store Connect → your app → **Monetization → In-App Purchases → +**:

| Product ID | Type | Price | Notes |
|---|---|---|---|
| `extra_life` | Consumable | Tier 1 (~$0.99) | One-shot life refill on out-of-lives |
| `extra_hint` | Consumable | Tier 1 (~$0.99) | One-shot extra hint per puzzle |
| `pro_unlock` | Non-consumable | Tier 5 (~$4.99) | Phase 6 — removes ads, +2 lives, Evil tier |

Each consumable can be re-purchased every game; the non-consumable can be restored across devices.

For each product: fill out display name, description, review screenshot. Submit for review — they're reviewed alongside your first app submission.

### Receipt verification

Apple's `verifyReceipt` endpoint:

- Production: `https://buy.itunes.apple.com/verifyReceipt`
- Sandbox: `https://sandbox.itunes.apple.com/verifyReceipt`

You need a **shared secret** for autorenewable receipts (not strictly required for consumables but good to set anyway). Get it from App Store Connect → My Apps → App Information → App-Specific Shared Secret.

This shared secret goes into the Phase 6 `verify-purchase` Edge Function (planned at `supabase/functions/verify-purchase/`). Set as a function secret:

```bash
supabase secrets set APPLE_SHARED_SECRET=...
```

---

## 2. Google Play (Android)

### Account

- **Google Play Console** — $25 one-time. Sign up at https://play.google.com/console.
- Create app, fill out store listing, content rating, target audience, etc. (boilerplate but mandatory before you can configure IAPs).

### In-app products

Play Console → your app → **Monetize → Products → In-app products → Create product**:

Same three product IDs as iOS (Google requires them to match across platforms in the Flutter `in_app_purchase` package): `extra_life`, `extra_hint`, `pro_unlock`. Fill price, description, activate.

### Receipt verification

Google requires a **service account** with read access to your purchases:

1. Play Console → **Settings → API access** → link a Google Cloud project → create a service account.
2. Grant the service account "Financial data, order management, app information" permission for your app.
3. Download the service account JSON key.
4. Upload to your Edge Function:

```bash
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT="$(cat /path/to/service-account.json)"
```

The Phase 6 Edge Function calls `androidpublisher.purchases.products.get` to verify each receipt.

---

## 3. AdMob (rewarded ads — "Watch for an extra life")

### Account

- **AdMob** — free. Sign up at https://admob.google.com.
- Add your app (Android + iOS as separate "apps" in AdMob — they get separate App IDs).

### Ad units

In AdMob → your app → **Ad units → Add ad unit → Rewarded**. Name it "Extra life rewarded". Save the ad-unit ID per platform.

### Test IDs (for dev)

Google publishes test ad unit IDs that show real ads but never pay you — safe for development:

- Android: `ca-app-pub-3940256099942544/5224354917`
- iOS: `ca-app-pub-3940256099942544/1712485313`

Use these via `--dart-define=ADMOB_REWARDED_AD_ID=...` until you're ready to flip to production.

### Manifest config (Android — required, otherwise the app crashes at startup)

`android/app/src/main/AndroidManifest.xml`, inside `<application>`:

```xml
<meta-data
  android:name="com.google.android.gms.ads.APPLICATION_ID"
  android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY" />
```

This is the **AdMob App ID**, not an ad-unit ID. Format: `ca-app-pub-...~...`. Get it from AdMob console → your app → App settings.

For iOS, add the equivalent `GADApplicationIdentifier` to `ios/Runner/Info.plist`.

> **Why this matters**: `google_mobile_ads` was removed from `pubspec.yaml` earlier in development because adding the package without this meta-data tag crashes the app at startup with `MobileAdsInitProvider: Missing application ID`. Add the meta-data BEFORE re-adding the package.

### GDPR / privacy

EU users need a consent dialog. Use the **Google UMP SDK** (`google_mobile_ads` ships with it). Required if the app is published in the EEA / UK.

---

## 4. (Optional) RevenueCat — abstracts Apple + Google + receipt verification

If managing two stores' APIs sounds painful, **RevenueCat** (https://revenuecat.com) is a SaaS that:

- Unifies iOS/Android purchases behind one SDK
- Handles receipt verification, restore, refunds
- Webhooks Supabase on grant/revoke (replaces the Phase 6 Edge Function)
- Free tier: $0/mo for the first $2,500/mo MRR; 1% above that

Trade-off: dependency on a third party + their cut. For an indie launch it's often worth it. The Flutter package is `purchases_flutter`. If you go this route, swap `MonetizationService` to call RevenueCat instead of `in_app_purchase` directly.

---

## 5. Wiring the real services into Flutter

When you have the accounts:

```yaml
# pubspec.yaml — re-add these (currently commented):
in_app_purchase: ^3.2.0
google_mobile_ads: ^5.2.0
```

Add an `IapMonetizationService` implementing the same `MonetizationService` interface. Switch the provider:

```dart
// lib/features/monetization/data/monetization_service.dart
final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  // return MockMonetizationService();         // dev / no accounts yet
  return IapMonetizationService(ref);          // production
});
```

The rest of the app keeps working unchanged — UI, controller, dialogs, tests.

---

## 6. Cost summary (one-time + recurring)

| Item | Cost | Frequency |
|---|---|---|
| Apple Developer Program | $99 | yearly |
| Google Play Console | $25 | one-time |
| AdMob | $0 | (free, you keep ~70%) |
| RevenueCat (optional) | $0 → 1% over $2.5k MRR | monthly |
| Supabase Edge Functions runtime | included up to 500k req/mo | monthly |
| **First year total (without RevenueCat)** | **~$124** | |

Apple takes 15% on year-1 revenue under $1M ARR (Small Business Program), 30% above. Google: same 15/30 structure.

---

## 7. Test plan

Before flipping to production:

- [ ] iOS sandbox tester: buy `extra_life` from sandbox account, verify life is granted, check `puzzle_attempts` server-side
- [ ] Google license tester (Play Console → Setup → License testing → add your Google account email): buy `extra_life`, verify receipt validation in the Edge Function logs
- [ ] AdMob test rewarded ad: trigger from the out-of-lives dialog, verify the reward callback fires
- [ ] Force-close mid-purchase: verify the receipt is reconciled on next launch via `restorePurchases()`
- [ ] Network drop during purchase: verify the user is not charged twice
- [ ] Refund flow: issue a refund via Apple/Google, verify the user's `is_pro` flag (Phase 6) flips back via webhook
