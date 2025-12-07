part of 'pages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse("$baseUrl/api/profile"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("STATUS CODE: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          profileData = json["data"];
          isLoading = false;
        });
      } else {
        print("Response Error: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = profileData;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF001932),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text("Gagal memuat data"))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ===== Header Profile (Card) =====
                      Stack(
                        children: [
                          Container(
                            height: 140,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 16,
                            right: 16,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 35,
                                      backgroundImage:
                                          AssetImage("assets/images/logo.jpg"),
                                    ),
                                    const SizedBox(width: 16),

                                    // INFORMASI NAMA + EMAIL
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data["nama"] ?? "-",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data["email"] ?? "-",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ===== DETAIL INFORMASI KARYAWAN =====
                      _sectionTitle("Informasi Karyawan"),
                      _infoTile("NIK", data["nik"], Icons.badge),
                      _infoTile(
                          "Departemen", data["departemen"], Icons.apartment),
                      _infoTile("Jabatan", data["jabatan"], Icons.work_outline),

                      const SizedBox(height: 15),

// ===== INFORMASI PRIBADI =====
                      _sectionTitle("Informasi Pribadi"),
                      _infoTile("Tempat Lahir", data["tempat_lahir"],
                          Icons.location_on_outlined),
                      _infoTile("Tanggal Lahir", data["tanggal_lahir"],
                          Icons.calendar_today),
                      _infoTile("Usia", data["usia"], Icons.timelapse),
                      _infoTile("Jenis Kelamin", data["JK"], Icons.wc),
                      _infoTile("Agama", data["agama"], Icons.account_balance),
                      _infoTile("Suku", data["suku"], Icons.group_outlined),
                      _infoTile("Nomor HP", data["no_hp"], Icons.phone),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ============================== WIDGET BANTUAN ==============================

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile(String label, dynamic value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label),
      subtitle: Text(value ?? "-"),
    );
  }
}
