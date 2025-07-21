part of '../../pages.dart';

class KLKHFuelStationShowPage extends StatefulWidget {
  final String id;
  

  const KLKHFuelStationShowPage({Key? key, required this.id}) : super(key: key);

  @override
  State<KLKHFuelStationShowPage> createState() => _KLKHFuelStationShowPageState();
}

class _KLKHFuelStationShowPageState extends State<KLKHFuelStationShowPage> {
  Map<String, dynamic>? detailData;
  bool isLoading = true;
  String? currentNik;
  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> _loadUserNik() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentNik = prefs.getString('nik'); 
    });
  }

  Future<void> fetchDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);
      final response = await http.get(
        Uri.parse('$baseUrl/api/klkh/fuel-station/preview/${widget.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          detailData = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      print('Error: $e');
      showErrorDialog('Gagal memuat data: $e');
    }
  }

  Future<void> _verifyDiketahui(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Verifikasi'),
        content: Text('Apakah Anda yakin ingin memverifikasi data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Verifikasi', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('$baseUrl/api/klkh/fuel-station/verified/diketahui/$id'), // pastikan endpoint benar
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');

      if (response.statusCode == 200) {
        showSuccessDialog('Data berhasil diverifikasi');
        fetchDetail(); // reload data setelah verifikasi
      } else {
        throw Exception('Verifikasi gagal');
      }
    } catch (e) {
      print('Error verifying data: $e');
      showErrorDialog('Gagal memverifikasi data: $e');
    }
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sukses'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }


  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terjadi Kesalahan'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  final Map<String, List<Map<String, String>>> categorizedChecklistItems = {
    
    'Lokasi Kerja': [
    {'key': 'PERMUKAAN_TANAH_RATA_CHECK', 'label': 'Permukaan tanah rata dan tidak berlubang'},
    {'key': 'PERMUKAAN_TANAH_LICIN_CHECK', 'label': 'Permukaan tanah tidak licin'},
    {'key': 'LOKASI_JAUH_LINTASAN_CHECK', 'label': 'Lokasi kerja jauh dengan lintasan aktif angkutan'},
    {'key': 'TIDAK_CECERAN_B3_CHECK', 'label': 'Tidak ada ceceran B3'},
    {'key': 'PARKIR_FUELTRUCK_CHECK', 'label': 'Area parkir khusus Fuel Truck untuk penyetokan tersedia'},
    {'key': 'PARKIR_LV_CHECK', 'label': 'Area parkir khusus untuk LV tersedia'},
    {'key': 'LAMPU_KERJA_CHECK', 'label': 'Semua lampu kerja menyala dengan normal dan memadai untuk kerja malam hari'},
    {'key': 'FUEL_GENSET_CHECK', 'label': 'Sisa fuel genset >10% kapasitas tangki'},
    {'key': 'AIR_BERSIH_TANDON_CHECK', 'label': 'Sisa air dalam tandon air bersih >30% kapasitas tandon'},
  ],
  'Perlengkapan Kerja': [
    {'key': 'SOP_JSA_CHECK', 'label': 'Tersedia SOP/ JSA untuk pekerjaan yang akan di lakukan'},
    {'key': 'SAFETY_POST_CHECK', 'label': 'Terpasang safety post sebagai batas berhenti unit untuk refueling'},
    {'key': 'RAMBU_APD_CHECK', 'label': 'Terpasang rambu peringatan dan rambu APD'},
    {'key': 'PERLENGKAPAN_KERJA_CHECK', 'label': 'Perlengkapan kerja ditata dengan rapi & tidak berserakan'},
    {'key': 'APAB_APAR_CHECK', 'label': 'Tersedia APAB dan APAR'},
    {'key': 'P3K_EYEWASH_CHECK', 'label': 'Tersedia kotak P3K dan Eyewash'},
    {'key': 'INSPEKSI_APAR_CHECK', 'label': 'Terdapat tag inspeksi APAR dan eyewash yang sudah di inspeksi'},
    {'key': 'FORM_CHECKLIST_REFUELING_CHECK', 'label': 'Tersedia form checklist peralatan Refueling'},
    {'key': 'TEMPAT_SAMPAH_CHECK', 'label': 'Tersedia tiga wadah / tempat penampung sampah'},
  ],
  'Kegiatan Refueling Unit A2B': [
    {'key': 'MINEPERMIT_CHECK', 'label': 'Fuelman memiliki dan membawa minepermit sebagai izin kerja'},
    {'key': 'SIMPER_OPERATOR_CHECK', 'label': 'Operator Fuel Truck memiliki dan membawa SIMPER sesuai peralatan yang digunakan'},
    {'key': 'PADLOCK_CHECK', 'label': 'Tersedia Padlock untuk kegiatan refueling'},
    {'key': 'WADAH_PENAMPUNG_CHECK', 'label': 'Tersedia wadah penampung untuk kegiatan Refueling'},
    {'key': 'WHEEL_CHOCK_CHECK', 'label': 'Tersedia ganjal / Wheel Chock'},
    {'key': 'RADIO_KOMUNIKASI_CHECK', 'label': 'Tersedia Radio Komunikasi'},
    {'key': 'APD_STANDAR_CHECK', 'label': 'Pekerja memakai APD standar dan APD tambahan jika di perlukan'},
  ],
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Preview Fuel Station', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF001932),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : detailData == null
              ? Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detail Inspeksi Fuel Station', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),

                      // INFO UMUM
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            InfoRow(label: 'PIT', value: ': ${detailData!['PIT']}'),
                            InfoRow(label: 'Tanggal', value: ': ${formatTanggal(detailData!['DATE'])}'),
                            InfoRow(label: 'Waktu', value: ': ${formatWaktu(detailData!['TIME'])}'),
                            InfoRow(label: 'Shift', value: ': ${detailData!['SHIFT']}'),
                            InfoRow(label: 'PIC', value: ': ${detailData!['NAMA_PIC']}'),
                            InfoRow(
                              label: 'Diketahui oleh',
                              valueWidget: Text.rich(
                                TextSpan(
                                  text: ': ${detailData!['NAMA_DIKETAHUI']} ',
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: detailData!['VERIFIED_DIKETAHUI'] == null
                                          ? '(Belum diverifikasi)'
                                          : '(Sudah diverifikasi)',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: detailData!['VERIFIED_DIKETAHUI'] == null ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // CHECKLIST
                      // CHECKLIST ITEM PER KATEGORI
                      Text('Checklist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),

                      ...categorizedChecklistItems.entries.map((category) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.key,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            SizedBox(height: 8),
                            ListView(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              children: category.value.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final key = item['key']!;
                                final value = detailData![key]; // nilai: 'true', 'false', atau 'n/a'
                                final noteKey = key.replaceFirst('_CHECK', '_NOTE');
                                final note = detailData?[noteKey];

                                // Konversi ke teks tampilan
                                String displayText;
                                switch (value) {
                                  case 'true':
                                    displayText = 'Ya';
                                    break;
                                  case 'false':
                                    displayText = 'Tidak';
                                    break;
                                  default:
                                    displayText = 'N/A';
                                }

                                // Tentukan warna berdasarkan index
                                final backgroundColor = index % 2 == 0 ? Colors.white : const Color.fromARGB(255, 240, 239, 239);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      )
                                    ],
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['label']!, style: TextStyle(fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('Checklist: $displayText', style: TextStyle(fontSize: 13)),
                                      if (note != null && note.toString().trim().isNotEmpty) ...[
                                        SizedBox(height: 6),
                                        Text('Catatan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                        Text(note.toString(), style: TextStyle(fontSize: 13, color: Colors.grey[800])),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      }

                      ).toList(),

                      

                      SizedBox(height: 20),

                      // CATATAN TAMBAHAN
                      if (detailData!['ADDITIONAL_NOTES'] != null)
                        Card(
                          color: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Catatan Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 8),
                                Text(detailData!['ADDITIONAL_NOTES']),
                              ],
                            ),
                          ),
                        ),

                      SizedBox(height: 20),

                     detailData!['VERIFIED_DIKETAHUI'] != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('QR Code Verifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 10),
                            Center(
                              child: QrImageView(
                                data: 'http://planner.ptsims.co.id/verified/${base64.encode(utf8.encode(detailData!['DIKETAHUI']))}',
                                version: QrVersions.auto,
                                size: 150.0,
                              ),
                            ),
                          ],
                        )
                      : detailData!['DIKETAHUI'] == currentNik
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Belum Diverifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                                SizedBox(height: 10),
                                ElevatedButton.icon(
                                  onPressed: () => _verifyDiketahui(widget.id),
                                  icon: Icon(Icons.verified_user, color: Colors.white),
                                  label: Text('Verifikasi Sekarang', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                ),
                              ],
                            )
                          : SizedBox(), // Tidak ditampilkan untuk user lain

                      SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }
}

// Widget untuk baris info
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const InfoRow({super.key, required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: valueWidget ?? Text(value ?? '')),
        ],
      ),
    );
  }
}
