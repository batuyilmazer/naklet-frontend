# Presentation-Only Theme Migration Plan

## Summary
- Amaç, mevcut nakliye uygulamasini is mantigina dokunmadan parodi bir sokak kedisi bulma uygulamasina cevirmek.
- Backend contractlari, repository'ler, auth akislari, route path'leri ve veri modelleri korunacak.
- Tum donusum presentation layer'da yapilacak: tema token'lari, kopya, ikonografi, kartlar, sekmeler ve metadata.

## Key Changes
- Global marka:
  - Uygulama adi `PisiBul` olacak.
  - `main.dart`, `web/index.html` ve `web/manifest.json` yeni kimlige gore guncellenecek.
- Terminoloji veneer'i:
  - `Driver` gorunen yerde `Sokak Kedisi`
  - `Vehicle` gorunen yerde `Kedi Profili`
  - `Customer/Guest` gorunen yerde `Kedi Seven`
- Alan esleme:
  - `Vehicle.type` -> kedi karakteri
  - `plateNumber` -> renk veya lakap
  - `capacityKg` -> tahmini kilo
  - Gerekli yerlerde yalnizca UI icin deterministic bir `yas / renk / lakap` sunumu uretilecek.
- Refactor kapsami:
  - `login_screen.dart`
  - `search_screen.dart`
  - `nearby_vehicle_card.dart`
  - `vehicle_detail_screen.dart`
  - `driver_register_screen.dart`
  - `add_vehicle_screen.dart`
  - `driver_dashboard_screen.dart`
  - `driver_profile_screen.dart`
  - `document_upload_screen.dart`
  - `shell_routes.dart`
  - `theme/*`

## Implementation Notes
- Yeni backend modeli veya payload degisikligi yapilmayacak.
- UI katmaninda ortak bir helper kullanilarak mevcut `driver/vehicle` verileri kedi profiline map edilecek.
- `VehicleType.label` ve `DriverStatus.label` gibi gorunen label'lar yeni tema diline gore guncellenecek.
- Theme palette lojistik tonlardan cikartilip sicak, oyunbaz ve mobil odakli bir gorunume tasinacak.
- Kartlar ve hero alanlari kedi temasini tasiyan yeni copy ve ikonografi ile guclendirilecek.

## Test Plan
- Gecersiz belge yukleme akisi yeni buton/metinlerle ayni davranisi vermeli.
- Guest search, login, driver dashboard ve add-vehicle akislari route ve submit davranisi olarak bozulmamali.
- UI icinde eski nakliye terminolojisi kalmadigi `rg` ile dogrulanmali.
- `flutter analyze` ve ilgili widget testleri temiz gecmeli.

## Assumptions
- Bu migration ilk fazda text, tema, ikonografi ve ekran duzenine odaklanir.
- Binary app icon yenilemesi kapsam disidir.
- Mizahi veneer tam gorunur olacak; teknik backend eslemeleri kullaniciya acik edilmeyecek.
