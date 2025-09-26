part of '../pages.dart';

class KkhListPage extends StatefulWidget {
  @override
  _KkhListPageState createState() => _KkhListPageState();
}

class _KkhListPageState extends State<KkhListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;
  bool isLoading = false;
  List<Map<String, dynamic>> fuelStationList = [];
  List<Map<String, dynamic>> filteredList = [];

  List<dynamic> namaList = [];
  List<dynamic> selectedIds = [];
  String? selectedNik; // dari Dropdown
  String selectedShift = "Semua";
  String selectedTypeVerified = "Semua";
  // Controllers
  final TextEditingController searchController = TextEditingController();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    _opacityController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000), // 1 detik naik turun
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _opacityController, curve: Curves.easeInOut),
    );
    fetchNama();

    _fetchKKHData();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _opacityController.dispose();
    searchController.dispose();
    super.dispose();
  }

  dynamic user = {};

  Future<void> fetchNama() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(SharedPrefKeys.user);
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse("$baseUrl/api/kkh/name"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaList = data["data"]; // ambil array dari JSON
          isLoading = false;
        });
      } else {
        throw Exception("Gagal mengambil data (${response.body})");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  Future<void> _verifikasiBanyakSekaligus() async {
    if (selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Konfirmasi"),
        content: Text(
            "Apakah kamu yakin ingin memverifikasi ${selectedIds.length} data terpilih?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text("Ya")),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.put(
        Uri.parse("$baseUrl/api/kkh/verifikasi/selection"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"id": selectedIds}),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        showSuccessDialog("Berhasil memverifikasi data terpilih");
        setState(() => selectedIds.clear());
        _fetchKKHData();
      } else {
        String msg = "Gagal memverifikasi data";
        print(selectedIds);
        try {
          final res = jsonDecode(response.body);
          if (res is Map) {
            if (res['message'] != null) {
              msg = res['message']; // ambil pesan utama
            }
            if (res['error'] != null) {
              msg += "\nDetail: ${res['error']}"; // tambahkan detail error kalau ada
            }
          }
        } catch (_) {}
        showErrorDialog(msg);
      }
    } catch (e) {
      Navigator.pop(context);
      showErrorDialog("Terjadi kesalahan: $e");
    }
  }

  Future<void> _fetchKKHData({String? nik}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(SharedPrefKeys.user);
      final token = prefs.getString(SharedPrefKeys.token);

      if (userData != null) {
        setState(() {
          user = json.decode(userData);
        });
      }

      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      // prioritas: param nik yg dikirim, kalau null gunakan selectedNik dari state
      String? nikParam;
      if (nik != null && nik.isNotEmpty) {
        nikParam = nik;
      } else if (selectedNik != null &&
                selectedNik!.isNotEmpty &&
                selectedNik != "Semua") {
        nikParam = selectedNik!.split(" - ")[0]; // ambil NIK saja dari "NIK - Name"
      }

      final queryParams = {
        'startDate': formattedStartDate,
        'endDate': formattedEndDate,
        if (nikParam != null) 'name': nikParam,
        if (selectedShift != "Semua") 'shift': selectedShift,
        if (selectedTypeVerified != "Semua") 'verifikasi': selectedTypeVerified,
      };

      print('Fetching KKH data with params: $queryParams');

      final uri = Uri.parse(baseUrl).replace(
        path: '/api/kkh',
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          fuelStationList =
              List<Map<String, dynamic>>.from(responseData['data']);
          filteredList = List.from(fuelStationList);
        });
      } else {
        throw Exception('Failed to load fuel station data');
      }
    } catch (e) {
      print('Error fetching fuel station data: $e');
      showErrorDialog('Gagal memuat data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != startDate) {
      setState(() {
        startDate = picked;
        if (startDate.isAfter(endDate)) {
          endDate = startDate;
        }
        _fetchKKHData();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != endDate) {
      setState(() {
        endDate = picked;
        _fetchKKHData();
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.delete(
        Uri.parse('${baseUrl}/api/klkh/fuel-station/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        showSuccessDialog('Data berhasil dihapus');
        _fetchKKHData();
      } else {
        final errorData = jsonDecode(response.body);

        final errorMessage = errorData['message'] ?? 'Terjadi kesalahan';
        // final errorDetail = errorData['error'] ?? '';

        throw Exception('$errorMessage');
      }
    } catch (e, stacktrace) {
      print('Error deleting data: $e');
      print('Stacktrace: $stacktrace');
      showErrorDialog('Gagal menghapus data:\n$e');
    }
  }

  void _filterData(String query) {
    setState(() {
      filteredList = fuelStationList.where((item) {
        final namaDiketahuiSearch =
            item['NAMA_DIKETAHUI']?.toString().toLowerCase() ?? '';
        final shiftSearch = item['SHIFT']?.toString().toLowerCase() ?? '';
        final pitSearch = item['PIT']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();

        return namaDiketahuiSearch.contains(searchLower) ||
            shiftSearch.contains(searchLower) ||
            pitSearch.contains(searchLower);
      }).toList();
    });
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Error', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Color(0xFF001932))),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Sukses', style: TextStyle(color: Colors.green)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: Color(0xFF001932))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKKHItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Nama pengisi + status verifikasi)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      item['VERIFIKASI'] == "1"
                          ? Row(
                              children: [
                                Icon(Icons.engineering, color: Colors.grey, size: 24),
                                SizedBox(width: 10),
                              ],
                            )
                          : Checkbox(
                              value: selectedIds.contains(item['id']),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedIds.add(item['id']);
                                  } else {
                                    selectedIds.remove(item['id']);
                                  }
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6), // rounded corner
                              ),
                              side: const BorderSide(
                                color: Colors.grey, // warna garis saat belum dipilih
                                width: 1.5,
                              ),
                              activeColor: const Color(0xFF001932), // warna utama saat terpilih
                              checkColor: Colors.white, // warna tanda centang
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // biar gak terlalu besar paddingnya
                            ),
                      SizedBox(width: 5),
                      Text(
                        item['NAMA_PENGISI'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item['VERIFIKASI'] == "1"
                          ? Colors.green[700]
                          : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['VERIFIKASI'] == "1"
                          ? 'Sudah diverifikasi'
                          : 'Belum diverifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Color(0xFF001932),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(), // Kolom judul otomatis ikut panjang terpanjang
                          1: FlexColumnWidth(), // Kolom isi fleksibel
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.top,
                        children: [
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Tanggal dibuat",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['TANGGAL_DIBUAT'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Shift",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['SHIFT'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Role",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['JABATAN'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Jam Pulang",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['JAM_PULANG'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Jam Tidur",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['JAM_TIDUR'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Jam Bangun",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['JAM_BANGUN'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Total Tidur",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['TOTAL_TIDUR'] ?? '-'} jam",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Fit Bekerja",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Align(
                                alignment:
                                    Alignment.centerLeft, // biar nempel kiri
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item['FIT_BEKERJA'] == '0'
                                        ? Colors.red
                                        : Colors.green,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    " ${item['FIT_BEKERJA'] == '1' ? "Ya" : "Tidak"} ",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.white),
                                  ),
                                ),
                              ),
                            )
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Keluhan",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['KELUHAN'] ?? '-'}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                          TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("Pengawas",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                  ": ${item['NAMA_PENGAWAS'] == null ? 'Tidak diketahui' : item['NAMA_PENGAWAS']}",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol aksi
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tombol verifikasi
                  if (item["CAN_VERIFY"] == true)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001932),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text("Konfirmasi"),
                              content: const Text(
                                  "Apakah kamu yakin ingin memverifikasi data ini?"),
                              actions: [
                                TextButton(
                                  child: const Text("Batal"),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                                TextButton(
                                  child: const Text("Ya, Verifikasi"),
                                  onPressed: () async {
                                    Navigator.of(dialogContext)
                                        .pop(); // Tutup dialog konfirmasi

                                    // 🔹 tampilkan loading dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    );

                                    try {
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      final token =
                                          prefs.getString(SharedPrefKeys.token);

                                      final response = await http.put(
                                        Uri.parse(
                                            "$baseUrl/api/kkh/verifikasi"),
                                        headers: {
                                          'Authorization': 'Bearer $token'
                                        },
                                        body: {"id": item['id'].toString()},
                                      );

                                      if (!context.mounted) return;

                                      Navigator.of(context)
                                          .pop(); // ✅ Tutup loading dialog

                                      if (response.statusCode == 200) {
                                        final data = jsonDecode(response.body);

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Berhasil"),
                                              content: Text(data['message'] ??
                                                  "Data berhasil diverifikasi!"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        _fetchKKHData();
                                      } else {
                                        final data = jsonDecode(response.body);

                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Gagal"),
                                              content: Text(data['message'] ??
                                                  "Gagal memverifikasi data."),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text("OK"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      Navigator.of(context)
                                          .pop(); // ✅ Tutup loading dialog
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text("Terjadi kesalahan: $e"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text(
                        "Verifikasi Sekarang",
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),

                  // Tombol edit (hanya jika belum diverifikasi & user adalah pengisi)

                  if (item['NIK_PENGISI'] == user['nik'] &&
                      item['VERIFIKASI'] != true) ...[
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KLKHFuelStationEditPage(
                              id: item['id'].toString(),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                  ],

                  // Tombol delete (role tertentu atau pengisi sebelum verifikasi)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper biar gak nulis berulang
  Widget buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "-",
              style: TextStyle(fontSize: 13, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:
            Text('Daftar KKH', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF001932),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectStartDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Dari Tanggal',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMM yyyy')
                                    .format(startDate)),
                                Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectEndDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Sampai Tanggal',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMM yyyy').format(endDate)),
                                Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  DropdownSearch<String>(
                    items: [
                      "Semua",
                      ...namaList.map<String>((item) {
                        return "${item['nik']} - ${item['name']}";
                      }).toList(),
                    ],
                    selectedItem: selectedNik,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Cari nama...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Pilih Nama",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedNik = value;
                      });

                      if (value == "Semua") {
                        _fetchKKHData(); // panggil API tanpa param
                      } else {
                        final nik = value!.split(" - ")[0]; // ambil hanya NIK
                        _fetchKKHData(); // kirim param nik ke API
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Shift',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        value: selectedShift,
                        items: ["Semua", "Pagi", "Malam"].map((shift) {
                          return DropdownMenuItem<String>(
                            value: shift,
                            child: Text(shift),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedShift = value!;
                          });
                          _fetchKKHData();
                        },
                      ),
                    ),
                    SizedBox(width: 12), // jarak antar dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status Verifikasi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        value: selectedTypeVerified,
                        items: ["Semua", "Belum diverifikasi", "Sudah diverifikasi"].map((typeverified) {
                          return DropdownMenuItem<String>(
                            value: typeverified,
                            child: Text(typeverified),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTypeVerified = value!;
                          });
                          _fetchKKHData();
                        },
                      ),
                    ),
                  ],
                )

                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: Image.asset(
                        'assets/images/spinning-loading.gif',
                        width: 200,
                      ),
                    )
                  : filteredList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada data ditemukan',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchKKHData,
                          color: Color(0xFF001932),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildKKHItem(filteredList[index]);
                            },
                          ),
                        ),
            ),
            if (selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity, // full width button
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedIds.isNotEmpty 
                          ? Colors.green[700] 
                          : Colors.grey, // disable color
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.verified, color: Colors.white, size: 22),
                    label: Text(
                      selectedIds.isNotEmpty
                          ? "Verifikasi ${selectedIds.length} data"
                          : "Pilih data untuk verifikasi",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: selectedIds.isNotEmpty 
                        ? _verifikasiBanyakSekaligus 
                        : null, // disable kalau kosong
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
