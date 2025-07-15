part of 'pages.dart';

class AktivitasPage extends StatefulWidget {
  @override
  _AktivitasPageState createState() => _AktivitasPageState();
}

class _AktivitasPageState extends State<AktivitasPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool isLoading = false;
  List<Map<String, dynamic>> aktivitasList = [];
  List<Map<String, dynamic>> filteredList = [];

  // Controllers
  final TextEditingController searchController = TextEditingController();
  int selectedMonth = DateTime.now().month;

  // Daftar bulan untuk dropdown
  final List<Map<String, dynamic>> months = [
    {"value": 1, "label": "Januari"},
    {"value": 2, "label": "Februari"},
    {"value": 3, "label": "Maret"},
    {"value": 4, "label": "April"},
    {"value": 5, "label": "Mei"},
    {"value": 6, "label": "Juni"},
    {"value": 7, "label": "Juli"},
    {"value": 8, "label": "Agustus"},
    {"value": 9, "label": "September"},
    {"value": 10, "label": "Oktober"},
    {"value": 11, "label": "November"},
    {"value": 12, "label": "Desember"},
  ];

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

    _fetchAktivitasData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAktivitasData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('${baseUrl}/api/activity/all?bulan=$selectedMonth'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          aktivitasList = List<Map<String, dynamic>>.from(responseData['data']);
          filteredList = List<Map<String, dynamic>>.from(aktivitasList);
        });
      } else {
        throw Exception('Failed to load aktivitas data');
      }
    } catch (e) {
      print('Error fetching aktivitas data: $e');
      showErrorDialog('Gagal memuat data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      filteredList = aktivitasList.where((item) {
        final nama = item['NAMA']?.toString().toLowerCase() ?? '';
        final nik = item['NIK']?.toString().toLowerCase() ?? '';
        final jenis = item['JENIS']?.toString().toLowerCase() ?? '';
        final keterangan = item['KETERANGAN']?.toString().toLowerCase() ?? '';
        final tanggal = item['TANGGAL']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();

        return nama.contains(searchLower) ||
            nik.contains(searchLower) ||
            jenis.contains(searchLower) ||
            keterangan.contains(searchLower) ||
            tanggal.contains(searchLower);
      }).toList();
    });
  }

  void _onMonthChanged(int? month) {
    if (month != null) {
      setState(() {
        selectedMonth = month;
      });
      _fetchAktivitasData(); // Panggil API dengan parameter bulan baru
    }
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

  Widget _buildAktivitasItem(Map<String, dynamic> item) {
    // Format tanggal untuk ditampilkan
    String formattedDate = '-';
    if (item['TANGGAL'] != null) {
      try {
        final date = DateTime.parse(item['TANGGAL']);
        formattedDate = DateFormat('dd MMM yyyy').format(date);
      } catch (e) {
        formattedDate = item['TANGGAL'];
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['NAMA'] ?? 'Unknown Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001932),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (item['STATUSENABLED'] == "1")
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (item['STATUSENABLED'] == "1") ? 'Aktif' : 'Tidak Aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'NIK: ${item['NIK'] ?? '-'}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              'Jenis: ${item['JENIS'] ?? '-'}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Tanggal: $formattedDate',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Keterangan: ${item['KETERANGAN'] ?? 'Tidak ada keterangan'}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Daftar Aktivitas',
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
                  // Filter Bulan saja
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedMonth,
                        hint: Text('Pilih Bulan'),
                        isExpanded: true,
                        items: months.map((month) {
                          return DropdownMenuItem<int>(
                            value: month['value'],
                            child: Text(month['label']),
                          );
                        }).toList(),
                        onChanged: _onMonthChanged,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Search Field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari aktivitas...',
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
            // Data Count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${filteredList.length} aktivitas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${months.firstWhere((m) => m['value'] == selectedMonth)['label']}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF001932),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            // List Data
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada aktivitas ditemukan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'untuk bulan ${months.firstWhere((m) => m['value'] == selectedMonth)['label']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchAktivitasData,
                          color: Color(0xFF001932),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildAktivitasItem(filteredList[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
