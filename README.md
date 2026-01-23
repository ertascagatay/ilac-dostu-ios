# İlaç Dostu 💊

Yaşlılar ve bakıcıları için geliştirilmiş, iOS odaklı ilaç takip uygulaması.

## 🌟 Özellikler

### Yaşlı Modu
- **Büyük, okunması kolay arayüz** - Yaşlı kullanıcılar için optimize edilmiş
- **Basit ilaç takibi** - Tek dokunuşla ilaç alındı olarak işaretle
- **Stok uyarısı** - İlaç stoğu azaldığında otomatik uyarı
- **Renkli göstergeler** - Sabah (turuncu) ve akşam (mavi) ilaçları kolayca ayırt et

### Bakıcı Modu
- **Uzaktan yönetim** - Sevdiklerinizin ilaçlarını uzaktan ekle/düzenle
- **Çoklu hasta** - Birden fazla kişinin ilaçlarını yönet
- **Eşleştirme kodu** - Güvenli ve kolay hasta bağlantısı
- **Gerçek zamanlı senkronizasyon** - Firebase ile senkronize

### iOS Home Screen Widget 📱
- **Ana ekran widget'ı** - Sıradaki ilacı ana ekranda gör
- **Otomatik güncelleme** - İlaç alındığında veya silindiğinde widget güncellenir
- **App Groups entegrasyonu** - Güvenli veri paylaşımı

### Teknik Özellikler
- ✅ **Firebase entegrasyonu** - Gerçek zamanlı veri senkronizasyonu
- ✅ **Yerel bildirimler** - İlaç zamanı hatırlatmaları
- ✅ **Çevrimdışı çalışma** - Shared Preferences ile yerel veri
- ✅ **iOS ve Web desteği** - Native iOS ve web platformları
- ✅ **Türkçe arayüz** - Tam Türkçe lokalizasyon

## 📋 Gereksinimler

- Flutter SDK 3.0.0 veya üzeri
- Dart SDK 3.0.0 veya üzeri
- **macOS** (iOS geliştirme için)
- **Xcode 14+** (iOS widget yapılandırması için)
- Firebase projesi

## 🚀 Kurulum

### 1. Bağımlılıkları Yükle
```bash
flutter pub get
```

### 2. Firebase Yapılandırması

#### iOS
1. [Firebase Console](https://console.firebase.google.com/)'da proje oluştur
2. iOS app ekle (bundle ID: `com.medtracker.ilacDostu`)
3. `GoogleService-Info.plist` dosyasını `ios/Runner/` klasörüne kopyala
4. Xcode'da projeyi aç ve `GoogleService-Info.plist`'i ekle

#### Web
`lib/main.dart` dosyasında Firebase web config'i güncelle (satır 36-43):
```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.firebasestorage.app",
    messagingSenderId: "YOUR_MESSAGING_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

### 3. iOS Widget Yapılandırması (Çok Önemli!)

Widget'ın çalışması için Xcode'da manuel yapılandırma gereklidir:

#### Adım 1: Xcode'da Projeyi Aç
```bash
open ios/Runner.xcworkspace
```

#### Adım 2: Ana App için App Groups Ekle
1. Xcode'da **Runner** target'ını seç
2. **Signing & Capabilities** sekmesine git
3. **+ Capability** butonuna tıkla
4. **App Groups** seç
5. **+ (Plus)** butonuna tıklayarak yeni grup ekle
6. Group identifier: `group.med_tracker`
7. Checkbox'ı işaretle

#### Adım 3: Widget Extension Oluştur (Eğer yoksa)
1. **File** → **New** → **Target**
2. **Widget Extension** seç
3. Product Name: `MedicationWidget`
4. **Include Configuration Intent** checkbox'ını KALDIR
5. **Finish** ve **Activate** yap

#### Adım 4: Widget Extension için App Groups Ekle
1. **MedicationWidget** target'ını seç
2. **Signing & Capabilities** sekmesine git
3. **+ Capability** → **App Groups**
4. Aynı `group.med_tracker` grubunu seç

#### Adım 5: Widget Kodunu Ekle
`ios/Runner/MedicationWidget.swift` dosyası zaten mevcut. Eğer widget extension oluşturduysan, bu dosyayı widget target'ına ekle.

### 4. Uygulamayı Çalıştır

#### Web (Test için)
```bash
flutter run -d chrome
```

#### iOS (Gerçek cihaz veya simulator)
```bash
flutter run -d ios
```

veya Xcode'dan:
1. Xcode'da **Runner** scheme'i seç
2. Cihaz/simulator seç
3. **▶️ Run** butonuna tıkla

## 📱 iOS Widget Kullanımı

1. Ana ekranda uzun bas
2. Sol üst köşedeki **+** butonuna tıkla
3. **İlaç Takip** widget'ını bul
4. Widget boyutu seç (Small veya Medium)
5. **Add Widget** tıkla
6. Widget'ı istediğin yere sürükle

## 📂 Proje Yapısı

```
lib/
├── main.dart              # Ana uygulama, tüm ekranlar ve iş mantığı
└── services/
    └── widget_service.dart # Home widget yönetimi

ios/
└── Runner/
    ├── Info.plist
    ├── GoogleService-Info.plist  # Firebase config (eklemen gerekli)
    └── MedicationWidget.swift    # iOS widget kodu
```

## 🎨 Kullanılan Teknolojiler

- **Flutter** - Cross-platform UI framework
- **Firebase Core & Firestore** - Gerçek zamanlı veritabanı
- **Shared Preferences** - Yerel veri saklama
- **Flutter Local Notifications** - Bildirimler (iOS)
- **Home Widget** - Ana ekran widget'ları
- **Google Fonts** - Inter font ailesi
- **SwiftUI** - iOS widget UI (native)

## 👥 Kullanım

### İlk Kullanım
1. Uygulamayı aç
2. Adınızı girin ve doğum tarihinizi seçin
3. **Yaşlı Modu** veya **Bakıcı Modu** seçin

### Yaşlı Modunda
- Ana ekranda ilaçlarınızı görün
- İlaç kartına dokunarak "alındı" olarak işaretleyin
- Yeşil renk ve ✓ işareti alındığını gösterir
- Ana ekran widget'ı sıradaki ilacı gösterir

### Bakıcı Modunda
- **+** butonuna tıklayarak hasta ekleyin
- Hasta eşleştirme kodunu girin
- Hasta seçip ilaçları yönetin

## 🔧 Sorun Giderme

### Widget Görünmüyor
- Xcode'da App Groups'un her iki target'ta da ekli olduğundan emin olun
- Group identifier'ın tam olarak `group.med_tracker` olduğunu kontrol edin
- Uygulamayı yeniden build edin ve çalıştırın

### Firebase Bağlantı Hatası
- `GoogleService-Info.plist` dosyasının doğru yerde olduğundan emin olun
- Bundle ID'nin Firebase Console'daki ile aynı olduğunu kontrol edin

## 📄 Lisans

Bu proje özel kullanım içindir.

---

**Not**: 
- iOS widget'ı için Xcode yapılandırması **zorunludur**
- Firebase yapılandırması için kendi Firebase projenizi oluşturmanız gerekmektedir
- Widget test etmek için gerçek iOS cihazı veya simulator kullanın
