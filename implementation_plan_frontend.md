# Naklet.net - Frontend Geliştirme Planı

Bu belge, Naklet.net uygulamasının frontend gelişim hattını tanımlar. Backend API'sine (`NAKLET_BACKEND_IMPLEMENTATION_PLAN.md`) tam uyumlu olarak hazırlanmıştır. Kod tabanında halihazırda var olan **Network, Auth, Storage, ve Routing** gibi özellikler atlanarak/modifiye edilerek sadece iş mantığına (Business Logic) ve kullanıcının istediği sıralamaya odaklanılmıştır.

## Sistem Rolleri

1. **Nakliyeci (Driver — Kayıtlı Kullanıcı):** `POST /drivers/register` ile kayıt olur. Profil + araç bilgileri otomatik olarak arama sonuçlarında görünür. **Araç bazlı** konumunu bildirmekle yükümlüdür. Admin onayından (`APPROVED`) sonra arama sonuçlarında görünmeye başlar.
2. **Müşteri — Yük Sahibi (Visitor — Kayıtsız Ziyaretçi):** Üye olmaz (bypass eder). `GET /search/nearby` ile yakındaki **aktif ve onaylanmış** nakliyecilerin araçlarını listeler. Kendi GPS konumunu bildirmekle yükümlüdür.

## Backend API Özeti (Referans)

| Endpoint | Method | Auth | Açıklama |
|---|---|---|---|
| `/auth/login` | POST | — | Mevcut kullanıcı girişi |
| `/drivers/register` | POST | — | Sürücü kaydı (User + Profile + Driver + Vehicle[]) |
| `/drivers/vehicles` | POST | authGuard | Yeni araç ekleme |
| `/drivers/vehicles/:vehicleId/active` | PATCH | authGuard | Araç aktif/pasif durumu |
| `/drivers/vehicles/:vehicleId/location` | POST | authGuard | Araç konum güncelleme (lat, lng) |
| `/drivers/documents` | PATCH | authGuard | Belge yükleme (ehliyet, ruhsat) |
| `/search/nearby` | GET | **Public** | Yakın araç arama (lat, lng, radius, vehicleType?) |
| `/admin/login` | POST | — | Admin girişi |
| `/admin/drivers/:id/approve` | PATCH | adminGuard | Sürücü onaylama |

## Veri Modelleri (Backend'e Uyumlu)

### Driver Modeli
```dart
class Driver {
  String id;
  DriverStatus status;    // PENDING | APPROVED | REJECTED
  String bio;
  int experienceYears;
  String? licenseFileId;
  String? registrationFileId;
  String userId;
  Profile profile;
  List<Vehicle> vehicles;
}
```

### Vehicle Modeli
```dart
class Vehicle {
  String id;
  VehicleType type;       // KAMYONET | PANELVAN | KAMYON | TIR
  String plateNumber;
  int capacityKg;
  bool isActive;
  double? lat;
  double? lng;
  String driverId;
}
```

### Profile Modeli
```dart
class Profile {
  String id;
  String firstName;
  String lastName;
  String phoneNumber;
  String userId;
}
```

### NearbyVehicle (Search Response)
```dart
class NearbyVehicle {
  String id;
  VehicleType type;
  String plateNumber;
  int capacityKg;
  double distance;         // metre cinsinden
  NearbyDriver driver;     // sürücü bilgisi
}

class NearbyDriver {
  String id;
  String firstName;
  String lastName;
}
```

### Enum'lar
```dart
enum VehicleType { KAMYONET, PANELVAN, KAMYON, TIR }
enum DriverStatus { PENDING, APPROVED, REJECTED }
```

---

## Geliştirme Aşamaları

### 👤 Aşama 1: Login Akışı Modifikasyonu (Ziyaretçi Bypass)

Mevcutta çalışan bir Authentication alt yapısı var. Ziyaretçileri bu duvarın etrafından dolaştırmamız gerekiyor.

- **[MODİFİYE] [login_screen.dart](file:///Users/yilmazer/projects/naklet/naklet-frontend/lib/features/auth/presentation/login_screen.dart)**: Login ekranına **"Kayıt Olmadan Devam Et (Ziyaretçi)"** butonu eklenecek.
- **[MODİFİYE] `lib/routing/guards/auth_guard.dart` & [app_router.dart](file:///Users/yilmazer/projects/naklet/naklet-frontend/lib/routing/app_router.dart)**: Ziyaretçi butonu kullanıldığında, session'a `Guest/Ziyaretçi` state'i işlenerek, AuthGuard'ın kullanıcıyı **Ana Sayfaya (Araç Arama Listesi)** yönlendirmesi sağlanacak.

---

### 🚛 Aşama 2: Sürücü Kayıt Akışı

Backend `POST /drivers/register` endpoint'i tek transaction'da User + Profile + Driver + Vehicle[] oluşturur. Frontend bunu çok adımlı bir form ile yakalamalıdır.

- **[YENİ] `lib/features/driver_registration/`**: Sürücü kayıt modülü
  - **`presentation/driver_register_screen.dart`**: Çok adımlı (stepper) kayıt formu:
    - **Adım 1 — Hesap Bilgileri:** email, password
    - **Adım 2 — Profil Bilgileri:** firstName, lastName, phoneNumber
    - **Adım 3 — Araç Bilgileri:** En az 1 araç zorunlu. Her araç için: `type` (VehicleType dropdown), `plateNumber`, `capacityKg`. Birden fazla araç eklenebilir.
  - **`data/driver_register_repository.dart`**: `POST /drivers/register` çağrısı. Request body:
    ```json
    {
      "email": "...",
      "password": "...",
      "firstName": "...",
      "lastName": "...",
      "phoneNumber": "...",
      "vehicles": [
        { "type": "KAMYONET", "plateNumber": "34ABC123", "capacityKg": 1500 }
      ]
    }
    ```
  - Response: access + refresh token → local storage'a kaydet ve ana sayfaya yönlendir.
- **[MODİFİYE] [login_screen.dart](file:///Users/yilmazer/projects/naklet/naklet-frontend/lib/features/auth/presentation/login_screen.dart)**: "Sürücü Olarak Kayıt Ol" butonu ile `driver_register_screen`'e navigasyon eklenecek.

---

### 🔍 Aşama 3: Araç Arama ve Listeleme (Public — Ziyaretçi Ana Sayfası)

Backend'de **ilan/post kavramı yoktur**. Sürücünün profil + araç bilgisi otomatik olarak arama sonuçlarında görünür. Arama `GET /search/nearby` endpoint'i üzerinden yapılır ve **auth gerektirmez**.

- **[YENİ] `lib/features/search/`**: Yakın araç arama modülü
  - **`data/search_repository.dart`**: `GET /search/nearby` çağrısı. Query parametreleri:
    - `lat` (double, zorunlu)
    - `lng` (double, zorunlu)
    - `radius` (int, metre cinsinden, max 50000 — varsayılan: 15000)
    - `vehicleType` (string, opsiyonel — `KAMYONET | PANELVAN | KAMYON | TIR`)
  - **`data/models/nearby_vehicle_model.dart`**: Backend response modeli:
    ```json
    {
      "vehicles": [
        {
          "id": "...",
          "type": "KAMYONET",
          "plateNumber": "34ABC123",
          "capacityKg": 1500,
          "distance": 2340.5,
          "driver": { "id": "...", "firstName": "Ali", "lastName": "Yılmaz" }
        }
      ]
    }
    ```
  - **`presentation/search_screen.dart`** (Ana Sayfa / Vitrin): Araç arama ve listeleme ekranı.
    - Üstte: Araç tipi filtresi (chip/dropdown — KAMYONET, PANELVAN, KAMYON, TIR veya Tümü)
    - Üstte: Mesafe (radius) ayarı slider — 5km, 10km, 15km, 20km, 50km
    - Alt: `NearbyVehicleCard` widget listesi — Sürücü adı, araç tipi, plaka, kapasite, mesafe gösterilir
  - **`presentation/widgets/nearby_vehicle_card.dart`**: Kompakt araç kartı widget'ı

- **[YENİ] `lib/features/search/presentation/vehicle_detail_screen.dart`**: Araç detay ekranı.
  - Sürücü tam profili: ad, soyad, bio, deneyim yılı
  - Araç bilgileri: tip, plaka, kapasite
  - Mesafe bilgisi
  - İletişim butonları (Aşama 6'da eklenecek)

---

### 📍 Aşama 4: Konum Servisleri

Sistemin ana mantığı konum tabanlı çalışır. Ziyaretçi kendi konumunu verir (yakın araç aramak için), sürücü ise **araç bazlı** konumunu günceller.

- **[YENİ] `lib/features/location/`**: Konum modülü
  - **`data/location_service.dart`**: `geolocator` paketini kullanarak cihaz konumunu alır. Konum izni (permission) akışını yönetir.
  - **Ziyaretçi (Müşteri) Tarafı:**
    - `search_screen.dart` açıldığında GPS konumu istenir.
    - Alınan `lat/lng`, `GET /search/nearby?lat=X&lng=Y&radius=15000` şeklinde gönderilir.
    - Konum alınamazsa kullanıcıya izin uyarısı gösterilir.
  - **Nakliyeci (Driver) Tarafı:**
    - Login olduktan sonra, uygulama arka planda (veya ana sayfada iken) `POST /drivers/vehicles/:vehicleId/location` endpoint'ine konum gönderir.
    - **Her aktif araç** için ayrı ayrı konum güncelleme yapılır (araç bazlı model).
    - Request body: `{ "lat": 41.0082, "lng": 28.9784 }`
    - Periyodik güncelleme (heartbeat): Belirli aralıklarla (ör. 30 sn) konum yenilenir.

---

### 🚗 Aşama 5: Sürücü Paneli (Dashboard)

Sürücünün araçlarını, durumunu ve profilini yönettiği ekranlar.

- **[YENİ] `lib/features/driver_dashboard/`**: Sürücü kontrol paneli
  - **`presentation/driver_dashboard_screen.dart`**: Sürücü ana ekranı:
    - **Onay Durumu Kartı:** `PENDING` → "Profiliniz inceleniyor", `APPROVED` → "Profiliniz onaylı, arama sonuçlarında görünüyorsunuz", `REJECTED` → "Profiliniz reddedildi"
    - **Araç Listesi:** Sürücünün kayıtlı tüm araçları. Her araç için:
      - Araç tipi, plaka, kapasite
      - `isActive` toggle (aktif/pasif) — `PATCH /drivers/vehicles/:vehicleId/active` çağırır
      - Son konum güncelleme zamanı
    - **Yeni Araç Ekle** butonu → araç ekleme formu
  - **`presentation/add_vehicle_screen.dart`**: Yeni araç ekleme formu
    - type (VehicleType dropdown), plateNumber, capacityKg
    - `POST /drivers/vehicles` endpoint'ine gönderilir
  - **`presentation/driver_profile_screen.dart`**: Sürücü profil görüntüleme/düzenleme
    - Ad, soyad, telefon, bio, deneyim yılı

---

### 📄 Aşama 6: Belge Yükleme

Sürücü ehliyet ve araç ruhsatı belgelerini yükler. Backend file servisi + `PATCH /drivers/documents` endpoint'i kullanılır.

- **[YENİ] `lib/features/documents/`**: Belge yükleme modülü
  - **`presentation/document_upload_screen.dart`**: Belge yükleme ekranı
    - Ehliyet fotoğrafı yükleme (FilePurpose: `DRIVER_LICENSE`)
    - Araç ruhsatı fotoğrafı yükleme (FilePurpose: `VEHICLE_REGISTRATION`)
    - Dosya seçim → file service'e upload → `PATCH /drivers/documents` ile onaylama
  - Request body:
    ```json
    {
      "licenseKey": "...",
      "licenseChecksum": "...",
      "registrationKey": "...",
      "registrationChecksum": "..."
    }
    ```

---

### 📞 Aşama 7: İletişim Araçları

- **[MODİFİYE] [pubspec.yaml](file:///Users/yilmazer/projects/naklet/naklet-frontend/pubspec.yaml)**: `url_launcher` paketi eklenecek.
- **[MODİFİYE] `vehicle_detail_screen.dart`**: İletişim butonları:
  - **Ara** butonu: `tel:+90XXXXXXXXXX` (sürücünün telefon numarası)
  - **WhatsApp** butonu: `https://wa.me/90XXXXXXXXXX`
  - Telefon numarası sürücünün `Profile.phoneNumber` alanından gelir.

---

### 🔮 Aşama 8: Gelecek (Backend Desteği Bekleniyor)

Aşağıdaki özellikler backend'de henüz endpoint olarak mevcut değildir. Backend geliştirildikçe eklenecektir:

- **Güven & Yorum Modülü:** Sürücü detayı altına yıldız ortalaması ve müşteri yorumları bileşeni.
- **Bildirimler (Push Notification):** Sürücüye yeni iş talebi, onay durumu bildirimi.
- **Admin Paneli (Web):** Sürücü onay/red yönetimi — `PATCH /admin/drivers/:id/approve` endpoint'i mevcut, frontend paneli henüz planlanmadı.

---

## Dosya Yapısı Özeti

```
lib/
├── features/
│   ├── auth/                         # Mevcut — Login/Register
│   │   └── presentation/
│   │       └── login_screen.dart     # MODİFİYE: Ziyaretçi bypass + Sürücü kayıt butonları
│   ├── driver_registration/          # YENİ — Sürücü çok adımlı kayıt
│   │   ├── data/
│   │   │   └── driver_register_repository.dart
│   │   └── presentation/
│   │       └── driver_register_screen.dart
│   ├── search/                       # YENİ — Yakın araç arama (Public)
│   │   ├── data/
│   │   │   ├── search_repository.dart
│   │   │   └── models/
│   │   │       └── nearby_vehicle_model.dart
│   │   └── presentation/
│   │       ├── search_screen.dart    # Ana Sayfa (Vitrin)
│   │       ├── vehicle_detail_screen.dart
│   │       └── widgets/
│   │           └── nearby_vehicle_card.dart
│   ├── location/                     # YENİ — GPS konum servisleri
│   │   └── data/
│   │       └── location_service.dart
│   ├── driver_dashboard/             # YENİ — Sürücü paneli
│   │   └── presentation/
│   │       ├── driver_dashboard_screen.dart
│   │       ├── add_vehicle_screen.dart
│   │       └── driver_profile_screen.dart
│   └── documents/                    # YENİ — Belge yükleme
│       └── presentation/
│           └── document_upload_screen.dart
├── routing/
│   ├── app_router.dart               # MODİFİYE: Yeni route'lar
│   └── guards/
│       └── auth_guard.dart           # MODİFİYE: Guest state desteği
└── ui/
    └── widgets/                      # Paylaşılan widget'lar
```

---

## Uygulama Sırası

1. **Aşama 1** — Login akışı + Ziyaretçi bypass (auth altyapısı modifikasyonu)
2. **Aşama 2** — Sürücü kayıt akışı (`POST /drivers/register`)
3. **Aşama 3** — Araç arama ve listeleme (`GET /search/nearby`)
4. **Aşama 4** — Konum servisleri (geolocator + konum güncelleme)
5. **Aşama 5** — Sürücü paneli (araç yönetimi, onay durumu)
6. **Aşama 6** — Belge yükleme
7. **Aşama 7** — İletişim araçları (url_launcher)
8. **Aşama 8** — Güven/Yorum + Bildirimler (backend desteği bekleniyor)
