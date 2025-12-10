# iMin POS Dual Display - Quick Start Guide

Implementasi cepat dual display untuk device iMin POS dengan Flutter.

## 🚀 Quick Setup

### 1. Copy Files

Copy file-file berikut ke project Anda:

```
android/app/src/main/kotlin/com/yourpackage/yourapp/
├── MainApplication.kt
└── MainActivity.kt

lib/
├── main.dart
├── screens/
│   ├── cashier_screen.dart
│   └── customer_screen.dart
```

### 2. Update AndroidManifest.xml

```xml
<application
    android:name=".MainApplication"  <!-- Tambahkan ini -->
    ...>
```

### 3. Update Package Names

Ganti `com.yourpackage.yourapp` dengan package name project Anda di:

- `MainApplication.kt`
- `MainActivity.kt`

### 4. Test

```bash
flutter run -d [imin_device_id]
```

## 🎯 Cara Pakai

### Mengaktifkan Customer Display

```dart
// Di cashier screen
await platform.invokeMethod('openSecondary');
```

### Update Konten Customer Display

```dart
await platform.invokeMethod('updateCustomerDisplay', {
  'message': 'Selamat datang!',
  'orderInfo': 'Nasi Gudeg + Es Teh',
  'totalAmount': 25000,
  'paymentStatus': 'processing', // processing, success, failed
  'promoMessage': 'Diskon 10% hari ini!',
});
```

### Menutup Customer Display

```dart
await platform.invokeMethod('closeSecondary');
```

## 📱 Method Channel API

| Method                  | Parameter              | Fungsi                 |
| ----------------------- | ---------------------- | ---------------------- |
| `checkSecondaryDisplay` | -                      | Cek dual display       |
| `openSecondary`         | -                      | Buka customer display  |
| `closeSecondary`        | -                      | Tutup customer display |
| `updateCustomerDisplay` | `Map<String, dynamic>` | Update konten          |

## 🔧 Troubleshooting

**Customer display tidak muncul?**

- Pastikan device iMin memiliki dual display
- Cek `MainApplication` terdaftar di AndroidManifest.xml

**Method channel error?**

- Restart app setelah perubahan native code
- Cek package name sudah benar

**Content tidak update?**

- Monitor logs: `flutter logs`
- Pastikan customer display sudah dibuka

## 📋 Checklist Implementation

- [ ] Copy `MainApplication.kt` dan `MainActivity.kt`
- [ ] Update `AndroidManifest.xml`
- [ ] Ganti package names
- [ ] Update nama toko di `CustomerPresentation`
- [ ] Test di device iMin fisik
- [ ] Implementasi UI cashier dan customer
- [ ] Test semua method channel calls

## 🎨 Kustomisasi

### Ubah Tampilan Customer Display

Edit di `MainActivity.kt` bagian `CustomerPresentation`:

```kotlin
// Ubah nama toko
val storeText = TextView(context).apply {
    text = "NAMA TOKO ANDA"  // Ganti ini
    ...
}

// Ubah warna background
setBackgroundColor(Color.parseColor("#1565C0"))  // Ganti warna
```

### Tambah Logo

```kotlin
// Tambah ImageView untuk logo
val logoView = ImageView(context).apply {
    setImageResource(R.drawable.your_logo)
    ...
}
layout.addView(logoView)
```

## 📚 Dokumentasi Lengkap

Lihat `IMIN_DUAL_DISPLAY_GUIDE.md` untuk dokumentasi lengkap dengan:

- Penjelasan detail implementasi
- Troubleshooting advanced
- Best practices
- API reference lengkap

---

**Ready to implement? Start with copying the files and updating package names!** 🚀
