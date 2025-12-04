part of '../pages.dart';

class SOPListPage extends StatefulWidget {
  @override
  _SOPListPageState createState() => _SOPListPageState();
}

class _SOPListPageState extends State<SOPListPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _opacityController;
  late Animation<double> _opacityAnimation;
  bool isLoading = false;
  List<Map<String, dynamic>> fuelStationList = [];
  List<Map<String, dynamic>> filteredList = [];

  List<dynamic> namaList = [];
  String? selectedName;

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

    _fetchSOPData();
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
        Uri.parse("$baseUrl/api/sop/name"),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaList = data["data"];
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

  Future<void> _fetchSOPData({String? name}) async {
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

      String? nameParam;
      if (name != null && name.isNotEmpty) {
        nameParam = name;
      } else if (selectedName != null &&
          selectedName!.isNotEmpty &&
          selectedName != "Semua") {
        nameParam = selectedName!.split(" - ")[0];
      }

      final queryParams = {
        if (nameParam != null) 'name': nameParam,
      };

      print('Fetching SOP data with params: $queryParams');

      final uri = Uri.parse(baseUrl).replace(
        path: '/api/sop',
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
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      showErrorDialog('Gagal memuat data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
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

  Widget _buildSOPItem(Map<String, dynamic> item) {
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
                              child: Text("SOP",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(": ${item['NAME'] ?? '-'}",
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
                      final uuid = item['UUID']?.toString() ?? '';

                      if (uuid.isEmpty) {
                        // optional: kasih info kalau UUID gak ada
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('UUID tidak ditemukan'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SOPDetailPage(uuid: uuid),
                        ),
                      );
                    },
                    child: const Text(
                      "Lihat",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
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
            Text('Daftar SOP', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  SizedBox(height: 16),
                  DropdownSearch<String>(
                    items: [
                      "Semua",
                      ...namaList.map<String>((item) {
                        return "${item['NAME']}";
                      }).toList(),
                    ],
                    selectedItem: selectedName,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: "Ketikkan nama SOP...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: "Cari SOP",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedName = value;
                      });

                      if (value == "Semua") {
                        _fetchSOPData(); // panggil API tanpa param
                      } else {
                        final name = value!.split(" - ")[0]; // ambil hanya name
                        _fetchSOPData(); // kirim param name ke API
                      }
                    },
                  ),
                  SizedBox(height: 16),
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
                          onRefresh: _fetchSOPData,
                          color: Color(0xFF001932),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildSOPItem(filteredList[index]);
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
