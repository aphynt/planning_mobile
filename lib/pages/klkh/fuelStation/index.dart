part of '../../pages.dart';


class KllhListPage extends StatefulWidget {
  @override
  _KllhListPageState createState() => _KllhListPageState();
}

class _KllhListPageState extends State<KllhListPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isLoading = false;
  List<Map<String, dynamic>> fuelStationList = [];
  List<Map<String, dynamic>> filteredList = [];

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

    _fetchFuelStationData();
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
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFuelStationData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

      final response = await http.get(
        Uri.parse(
            '${baseUrl}/api/klkh/fuel-station?startDate=$formattedStartDate&endDate=$formattedEndDate'),
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
        _fetchFuelStationData();
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
        _fetchFuelStationData();
      });
    }
  }
  
  Future<void> _downloadPdf(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Download data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Download', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    showLoadingDialog(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('${baseUrl}/api/klkh/fuel-station/download/$id'),
        headers: {
          'Accept': 'application/pdf',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Save the PDF file
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/KLKH Fuel Station_$id.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        hideLoadingDialog(context);

        // Open the PDF file
        OpenFile.open(filePath);

        showSuccessDialog('PDF berhasil didownload');
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      hideLoadingDialog(context);
      print('Error downloading PDF: $e');
      showErrorDialog('Gagal mendownload PDF: $e');
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
        _fetchFuelStationData();
      } else {
        throw Exception('Failed to delete data');
      }
    } catch (e) {
      print('Error deleting data: $e');
      showErrorDialog('Gagal menghapus data: $e');
    }
  }

  void _filterData(String query) {
    setState(() {
      filteredList = fuelStationList.where((item) {
        final namaDiketahuiSearch = item['NAMA_DIKETAHUI']?.toString().toLowerCase() ?? '';
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

  Widget _buildFuelStationItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowPage(id: item['ID'].toString()),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12), // lebih rapat antar card
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background5.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Blur overlay
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['PIT'] ?? 'Unknown PIT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item['VERIFIED_DIKETAHUI'] == null
                                    ? Colors.red
                                    : Colors.green[700],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['VERIFIED_DIKETAHUI'] == null
                                    ? 'Belum diverifikasi'
                                    : 'Sudah diverifikasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tanggal: ${formatTanggal(item['DATE'])}',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Waktu: ${formatWaktu(item['TIME'])}',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Diketahui: ${item['NAMA_DIKETAHUI'] ?? '-'}',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                        // Tombol aksi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20), // Jarak kanan dari tombol pertama
                              child: IconButton(
                                icon: Icon(Icons.download, color: Colors.white),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                                onPressed: () => _downloadPdf(item['ID'].toString()),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                              onPressed: () => _deleteItem(item['ID'].toString()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Daftar Checklist Fuel Station',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF001932), width: 1.5),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _filterData,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF001932)),
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
                          onRefresh: _fetchFuelStationData,
                          color: Color(0xFF001932),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildFuelStationItem(filteredList[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FuelStationPage(),
            ),
          ).then((_) => _fetchFuelStationData());
        },
        backgroundColor: Color(0xFF001932),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
