part of 'pages.dart';


class Banner {
  final String filename;
  final String url;

  Banner({required this.filename, required this.url});

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      filename: json['filename'],
      url: json['url'],
    );
  }
}

class AbsensiData {
  final String code;
  final String masuk;
  final String pulang;

  AbsensiData({
    required this.code,
    required this.masuk,
    required this.pulang,
  });

  factory AbsensiData.fromJson(Map<String, dynamic> json) {
    return AbsensiData(
      code: json['CODE'],
      masuk: json['MASUK'] ?? '-',
      pulang: json['PULANG'] ?? '-',
    );
  }
}

class ActivitySummary {
  final String id;
  final String statusEnabled;
  final String tanggal;
  final String jenis;
  final String nama;
  final String nik;
  final String keterangan;

  ActivitySummary({
    required this.id,
    required this.statusEnabled,
    required this.tanggal,
    required this.jenis,
    required this.nama,
    required this.nik,
    required this.keterangan,
  });

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      id: json['ID'],
      statusEnabled: json['STATUSENABLED'] ?? false,
      tanggal: json['TANGGAL'],
      jenis: json['JENIS'],
      nama: json['NAMA'],
      nik: json['NIK'],
      keterangan: json['KETERANGAN'],
    );
  }
}


Future<List<Banner>> fetchBanners() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(SharedPrefKeys.token);

  while (true) {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}/api/banner'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> bannerData = jsonResponse['data'];

        if (bannerData.isNotEmpty) {
          return bannerData.map((banner) => Banner.fromJson(banner)).toList();
        }
      }
    } catch (e) {
      print('Error fetching banners: $e');
    }

    // Tunggu 3 detik sebelum mencoba lagi
    await Future.delayed(Duration(seconds: 3));
  }
}

Future<AbsensiData?> fetchAbsensiData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(SharedPrefKeys.token);

  try {
    final response = await http.get(
      Uri.parse('${baseUrl}/api/absensi'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      print(jsonResponse);
      if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null && jsonResponse['data'].isNotEmpty) {
        return AbsensiData.fromJson(jsonResponse['data'][0]);
      }
    }
  } catch (e) {
    print('Error fetching absensi data: $e');
  }
  return null;
}

String formatDateString(String originalDate) {
  try {
    // Parse string ke DateTime
    DateTime dateTime = DateTime.parse(originalDate);
    
    // Format ke format yang diinginkan: dd-MM-yyyy HH:mm
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
    
    return formattedDate;
  } catch (e) {
    print('Error parsing date: $e');
    return originalDate; // Return original jika ada error
  }
}

Future<List<ActivitySummary>> fetchActivitySummary() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(SharedPrefKeys.token);

  try {
    final response = await http.get(
      Uri.parse('${baseUrl}/api/activity/summary'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token}',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
        final List<dynamic> activityData = jsonResponse['data'];
        return activityData.map((activity) => ActivitySummary.fromJson(activity)).toList();
      }
    }
  } catch (e) {
    print('Error fetching activity summary: $e');
  }
  return [];
}

class MainPage extends StatefulWidget {
  final String responseMessage;

  const MainPage({Key? key, required this.responseMessage}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF001932);
  final Color accentColor = const Color(0xFF00C2FF);

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.post(
        Uri.parse('${baseUrl}/api/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Hapus token dan user data dari SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(SharedPrefKeys.token);
        await prefs.remove(SharedPrefKeys.user);

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil keluar')),
        );
      } else {
        // Tampilkan pesan error jika logout gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal keluar: ${response.reasonPhrase}')),
        );
      }
    } finally {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  dynamic user = {};
  AbsensiData? absensiData;
  List<ActivitySummary> activitySummaries = [];

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(SharedPrefKeys.user);
    if (userData != null) {
      setState(() {
        user = json.decode(userData);
      });
    }
  }

  Future<void> _loadAbsensiData() async {
    final data = await fetchAbsensiData();
    if (mounted) {
      setState(() {
        absensiData = data;
      });
    }
  }

  Future<void> _loadActivitySummary() async {
    final data = await fetchActivitySummary();
    if (mounted) {
      setState(() {
        activitySummaries = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAbsensiData();
    _loadActivitySummary();
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // Threshold untuk layar kecil

    return Scaffold(
      body: Stack(
      children: [
        // Gambar latar belakang dengan opacity
        Opacity(
          opacity: 0.2,
          child: Image.asset(
            'assets/images/background2.jpg', // Ganti sesuai path gambar kamu
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Center(child: Text('Image not found'));
            },
          ),
        ),

        // Konten utama di atas background
        Positioned.fill(
          child: _buildBodyContent(),
        ),
      ],
    ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'Aktivitas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pie_chart_outline_rounded),
                activeIcon: Icon(Icons.pie_chart),
                label: 'Statistik',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Info'),
          content: Text('Fitur ini belum difungsikan!'),
          actions: <Widget>[
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Tentang Aplikasi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'PlannER',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF198754), // Bootstrap success green
                ),
              ),
              SizedBox(height: 4),
              Text('Versi 1.0.1'),
              SizedBox(height: 8),
              Text(
                'Planning E-Report',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Tutup',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildQuickAction(String label, IconData icon, onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  Widget _buildActivityItem(ActivitySummary activity) {
    IconData activityIcon;
    Color activityColor;
    
    // Set icon dan warna berdasarkan jenis kegiatan
    switch (activity.jenis.toLowerCase()) {
      case 'kegiatan':
        activityIcon = Icons.work_outline;
        activityColor = Colors.blue;
        break;
      case 'monitoring':
        activityIcon = Icons.visibility_outlined;
        activityColor = Colors.green;
        break;
      case 'laporan':
        activityIcon = Icons.description_outlined;
        activityColor = Colors.orange;
        break;
      default:
        activityIcon = Icons.event_note_outlined;
        activityColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                activityIcon,
                color: activityColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.keterangan,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.nama} • ${activity.jenis}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(activity.tanggal),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: activity.statusEnabled=="1" ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada aktivitas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aktivitas terbaru akan muncul di sini',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final targetDate = DateTime(date.year, date.month, date.day);

      if (targetDate == today) {
        return 'Hari ini';
      } else if (targetDate == yesterday) {
        return 'Kemarin';
      } else {
        // Format: 13 Jul 2025
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
                       'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }


  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage(); // isinya dari MainPage sebelumnya
      case 1:
        return AktivitasPage(); // Sudah ada
      case 2:
        Future.microtask(() => _showComingSoonDialog());
        return _buildComingSoonPage(); // agar tetap render sesuatu
      case 3:
      case 4:
        return _buildComingSoonPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildBlankPage() {
    return Container(); // Kosong tapi tidak error
  }

  Widget _buildComingSoonPage() {
    return Center(
      child: Text(
        'Coming Soon!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildHomePage() {
  final screenHeight = MediaQuery.of(context).size.height;
  final isSmallScreen = screenHeight < 700;

  return LayoutBuilder(
    builder: (context, constraints) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Column(
            children: [
              // Header dengan background image (tinggi disesuaikan)
                  Container(
                    height: isSmallScreen ? 220 : 270,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [primaryColor, const Color(0xFF003366)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background image
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.2, 
                            child: Image.asset(
                              'assets/images/gali2.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(child: Text('Image not found'));
                              },
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // AppBar content
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    
                                    Text(
                                      'Hi, ${user['name'] ?? 'User'}!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.emoji_emotions,
                                      color: Color(0xFF198754), // Bootstrap 'success' green
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.notifications_outlined,
                                              color: Colors.white),
                                          onPressed: () {},
                                        ),
                                        PopupMenuButton<int>(
                                          icon: const Icon(Icons.more_vert,
                                              color: Colors.white),
                                          onSelected: (value) {
                                            if (value == 1) {
                                              _showAboutDialog();
                                            } else if (value == 2) {
                                              logout(); // pastikan logout tidak butuh await di sini
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 1,
                                              child: Text("Tentang Aplikasi"),
                                            ),
                                            const PopupMenuItem(
                                              value: 2,
                                              child: Text("Keluar"),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Balance Card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              color: Colors.white70),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Kehadiran Hari Ini',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      if (absensiData != null) ...[
                                        _buildAttendanceInfo('Kode', absensiData!.code),
                                        const SizedBox(height: 5),
                                        _buildAttendanceInfo('Masuk', formatDateString(absensiData!.masuk)),
                                        const SizedBox(height: 5),
                                        _buildAttendanceInfo('Pulang', formatDateString(absensiData!.pulang)),
                                      ] else ...[
                                        _buildAttendanceInfo('Kode', '-'),
                                        const SizedBox(height: 5),
                                        _buildAttendanceInfo('Masuk', '-'),
                                        const SizedBox(height: 5),
                                        _buildAttendanceInfo('Pulang', '-'),
                                      ],
                                    ],
                                  ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions Grid (dengan tinggi dinamis)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: SizedBox(
                    height: isSmallScreen ? 180 : 220,
                    child: GridView.count(
                      crossAxisCount: 4,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: [
                        _buildQuickAction('KLKH Fuel Station', Icons.assignment_turned_in, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KllhListPage(),
                            ),
                          );
                        }),
                        _buildQuickAction('KKH', Icons.engineering, () {
                          _showComingSoonDialog();
                        }),
                        _buildQuickAction('P2H', Icons.assignment, () {
                          _showComingSoonDialog();
                        }),
                        _buildQuickAction('FuelMan', Icons.local_gas_station, () {
                          _showComingSoonDialog();
                        }),
                        
                      ],
                    ),
                  ),
                  ),

                  // Promo Banner (dengan tinggi lebih kecil untuk layar kecil)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FutureBuilder<List<Banner>>(
                      future: fetchBanners(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: isSmallScreen ? 120 : 150,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (snapshot.hasError) {
                          return SizedBox(
                            height: isSmallScreen ? 120 : 150,
                            child: Center(child: Text('Gagal memuat banner')),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return SizedBox(
                            height: isSmallScreen ? 120 : 150,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    const Color(0xFF0095E0)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'Tidak ada banner tersedia',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }

                        final banners = snapshot.data!;
                        return SizedBox(
                          height: isSmallScreen ? 160 : 200,
                          child: CarouselSlider.builder(
                            itemCount: banners.length,
                            options: CarouselOptions(
                              autoPlay: true,
                              enlargeCenterPage: true,
                              aspectRatio: isSmallScreen ? 2.0 : 2.5,
                              autoPlayInterval: Duration(seconds: 3),
                              viewportFraction: 1.0,
                            ),
                            itemBuilder: (context, index, realIdx) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl: banners[index].url,
                                    httpHeaders: {
                                      'Accept': 'image/*',
                                    },
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.error),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Recent Transactions Section (dengan jumlah item dinamis)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Aktivitas Terakhir',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                MaterialPageRoute(builder: (context) => AktivitasPage()),
                                );
                              },
                              child: Text(
                                'Lihat Semua',
                                style: TextStyle(color: accentColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (activitySummaries.isNotEmpty) ...[
                          ...activitySummaries.take(isSmallScreen ? 3 : 4).map((activity) => 
                            _buildActivityItem(activity)
                          ).toList(),
                        ] else ...[
                          _buildEmptyActivityState(),
                        ],
                      ],
                    ),
                  ),

                  // Bottom padding untuk menghindari overflow
                  SizedBox(height: isSmallScreen ? 20 : 40),
            ],
          ),
        ),
      );
    },
  );
}

}
