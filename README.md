<h1 align="center">📱 PlannER</h1>
<p align="center">
  <em>Aplikasi Flutter untuk KLKH & KKH dengan verifikasi dan pencatatan harian</em>
</p>

---

## 🚀 Fitur Utama

<div align="center">

<table>
<tr>
  <td>✅ <b>KLKH</b> <br> (Kelayakan Lingkungan Kerja Harian)</td>
  <td>✅ <b>KKH</b> <br> (Kesiapan Kerja Harian)</td>
  <td>📝 <b>Catatan Tambahan</b></td>
</tr>
<tr>
  <td>
    <ul>
      <li>Checklist kondisi lingkungan kerja</li>
      <li>Dokumentasi & catatan temuan</li>
      <li>Verifikasi supervisor</li>
    </ul>
  </td>
  <td>
    <ul>
      <li>Checklist kesiapan personil & peralatan</li>
      <li>Input cepat & mudah</li>
      <li>Verifikasi sebelum aktivitas dimulai</li>
    </ul>
  </td>
  <td>
    <ul>
      <li>Pencatatan umum harian</li>
      <li>Riwayat catatan rapi</li>
      <li>Lampiran foto/dokumen</li>
    </ul>
  </td>
</tr>
</table>

</div>

---

## 🔐 Verifikasi
- Setiap KLKH & KKH dapat diverifikasi melalui sistem.  
- QR Code ditampilkan sebagai bukti validasi.  
- Data terhubung ke backend Laravel (API).

---

## 🛠️ Teknologi
<div align="center">

| Bagian      | Teknologi |
|-------------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend**  | Laravel REST API |
| **Database** | SQL Server |
| **Auth**     | Laravel Sanctum / JWT |
| **State Mgmt** | Provider / Riverpod |

</div>

---

## 📦 Instalasi

```bash
# Clone project
git clone https://github.com/ahmadfadillllah/planning_mobile.git
cd planning_mobile

# Install dependency
flutter pub get

# Jalankan aplikasi
flutter run

lib/
├── main.dart              # Entry point
├── pages/                 # Halaman (Login, Dashboard, KLKH, KKH, dll)
├── widgets/               # UI reusable components
├── models/                # Data models
├── services/              # API services
└── providers/             # State management


<p align="center">👨‍💻 <b>Developed with <a href="https://ahmadfadillah.my.id">ahmadfadillllah</a> ❤️ using Flutter & Laravel</b></p>
