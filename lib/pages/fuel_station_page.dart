part of 'pages.dart';

class FuelStationPage extends StatefulWidget {
  @override
  _FuelStationPageState createState() => _FuelStationPageState();
}

class _FuelStationPageState extends State<FuelStationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Basic Info Controllers
  final TextEditingController pitController = TextEditingController();
  final TextEditingController shiftController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController additionalNotesController =
      TextEditingController();
  final TextEditingController diketahuiController = TextEditingController();

  // Lists for dropdown data
  List<Map<String, dynamic>> pitList = [];
  List<Map<String, dynamic>> shiftList = [];
  List<Map<String, dynamic>> diketahuiList = [];

  // Selected values
  String? selectedPitId;
  String? selectedShiftId;
  String? selectedDiketahuiNik;

  // Checklist items with their corresponding note controllers
  final Map<String, String> checklistItems = {
    'PERMUKAAN_TANAH_RATA': 'Permukaan Tanah Rata',
    'PERMUKAAN_TANAH_LICIN': 'Permukaan Tanah Licin',
    'LOKASI_JAUH_LINTASAN': 'Lokasi Jauh Lintasan',
    'TIDAK_CECERAN_B3': 'Tidak Ceceran B3',
    'PARKIR_FUELTRUCK': 'Parkir Fuel Truck',
    'PARKIR_LV': 'Parkir LV',
    'LAMPU_KERJA': 'Lampu Kerja',
    'FUEL_GENSET': 'Fuel Genset',
    'AIR_BERSIH_TANDON': 'Air Bersih Tandon',
    'SOP_JSA': 'SOP JSA',
    'SAFETY_POST': 'Safety Post',
    'RAMBU_APD': 'Rambu APD',
    'PERLENGKAPAN_KERJA': 'Perlengkapan Kerja',
    'APAB_APAR': 'APAB APAR',
    'P3K_EYEWASH': 'P3K Eyewash',
    'INSPEKSI_APAR': 'Inspeksi APAR',
    'FORM_CHECKLIST_REFUELING': 'Form Checklist Refueling',
    'TEMPAT_SAMPAH': 'Tempat Sampah',
    'MINEPERMIT': 'Mine Permit',
    'SIMPER_OPERATOR': 'Simper Operator',
    'PADLOCK': 'Padlock',
    'WADAH_PENAMPUNG': 'Wadah Penampung',
    'WHEEL_CHOCK': 'Wheel Chock',
    'RADIO_KOMUNIKASI': 'Radio Komunikasi',
    'APD_STANDAR': 'APD Standar',
  };

  // Maps to store check values and note controllers
  Map<String, String> checkValues = {};
  Map<String, TextEditingController> noteControllers = {};

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

    // Initialize check values and note controllers
    checklistItems.forEach((key, value) {
      checkValues[key] = 'n/a';
      noteControllers[key] = TextEditingController();
    });

    // Set default date and time
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    timeController.text = DateFormat('HH:mm').format(DateTime.now());

    // Fetch dropdown data
    _fetchPitData();
    _fetchShiftData();
    _fetchDiketahuiData();
  }

  Future<void> _fetchPitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('http://36.67.119.212:9013/api/area'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        setState(() {
          pitList = List<Map<String, dynamic>>.from(
              responseData['data'].map((item) => {
                    'id': item['ID'].toString(),
                    'keterangan': item['KETERANGAN'].toString(),
                  }));
        });
      } else {
        throw Exception('Failed to load PIT data');
      }
    } catch (e) {
      print('Error fetching PIT data: $e');
    }
  }

  Future<void> _fetchShiftData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('http://36.67.119.212:9013/api/shift'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          shiftList = List<Map<String, dynamic>>.from(
              responseData['data'].map((item) => {
                    'id': item['ID'].toString(),
                    'keterangan': item['KETERANGAN'].toString(),
                  }));
        });
      } else {
        throw Exception('Failed to load SHIFT data');
      }
    } catch (e) {
      print('Error fetching SHIFT data: $e');
    }
  }

  Future<void> _fetchDiketahuiData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('http://36.67.119.212:9013/api/users/diketahui'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          diketahuiList = List<Map<String, dynamic>>.from(
              responseData['data'].map((item) => {
                    'nik': item['NIK'].toString(),
                    'nama': item['NAMA'].toString(),
                  }));
        });
      } else {
        throw Exception('Failed to load DIKETAHUI data');
      }
    } catch (e) {
      print('Error fetching DIKETAHUI data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    pitController.dispose();
    shiftController.dispose();
    dateController.dispose();
    timeController.dispose();
    additionalNotesController.dispose();
    diketahuiController.dispose();
    noteControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text = picked.format(context);
      });
    }
  }

  Future<void> submitData() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    Map<String, dynamic> requestBody = {
      'PIT': selectedPitId,
      'SHIFT': selectedShiftId,
      'DATE': dateController.text,
      'TIME': timeController.text,
      'ADDITIONAL_NOTES': additionalNotesController.text,
      'DIKETAHUI': selectedDiketahuiNik,
    };

    // Add checklist items
    checklistItems.forEach((key, value) {
      requestBody['${key}_CHECK'] = checkValues[key];
      requestBody['${key}_NOTE'] = noteControllers[key]!.text;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPrefKeys.token);
    print(jsonEncode(requestBody));
    final response = await http.post(
      Uri.parse('http://36.67.119.212:9013/api/klkh/fuel-station'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    final responseData = jsonDecode(response.body);
    print(responseData);

    if (response.statusCode == 201) {
      // Show success dialog and redirect when OK is clicked
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Berhasil', style: TextStyle(color: Colors.green)),
              ],
            ),
            content: Text(responseData['message'] ?? 'Data berhasil disimpan'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KllhListPage(), // Replace with your list page
                    ),
                  );
                },
                child: Text('OK', style: TextStyle(color: Color(0xFF001932))),
              ),
            ],
          );
        },
      );
      _resetForm();
    } else {
      showErrorDialog(responseData['message'] ?? 'Gagal menyimpan data');
    }
  } catch (e) {
    showErrorDialog('Terjadi kesalahan: $e');
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      selectedPitId = null;
      selectedShiftId = null;
      selectedDiketahuiNik = null;
    });
    dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    timeController.text = DateFormat('HH:mm').format(DateTime.now());
    additionalNotesController.clear();

    setState(() {
      checklistItems.forEach((key, value) {
        checkValues[key] = 'n/a';
        noteControllers[key]!.clear();
      });
    });
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Berhasil', style: TextStyle(color: Colors.green)),
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

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              child: Text('Close', style: TextStyle(color: Color(0xFF001932))),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChecklistItem(String key, String title) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF001932),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Ya', style: TextStyle(fontSize: 14)),
                    value: 'true',
                    groupValue: checkValues[key],
                    onChanged: (value) {
                      setState(() {
                        checkValues[key] = value!;
                      });
                    },
                    activeColor: Color(0xFF001932),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Tidak', style: TextStyle(fontSize: 14)),
                    value: 'false',
                    groupValue: checkValues[key],
                    onChanged: (value) {
                      setState(() {
                        checkValues[key] = value!;
                      });
                    },
                    activeColor: Color(0xFF001932),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('N/A', style: TextStyle(fontSize: 14)),
                    value: 'n/a',
                    groupValue: checkValues[key],
                    onChanged: (value) {
                      setState(() {
                        checkValues[key] = value!;
                      });
                    },
                    activeColor: Color(0xFF001932),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: noteControllers[key],
              decoration: InputDecoration(
                labelText: 'Catatan',
                hintText: 'Masukkan catatan (opsional)',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF001932), width: 2),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
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
        title: Text('Fuel Station Checklist',
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF001932), Color(0xFF003366)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Dasar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'PIT',
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.white, width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            dropdownColor: Color(0xFF003366),
                            style: TextStyle(color: Colors.white),
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            value: selectedPitId,
                            items: pitList.map((pit) {
                              return DropdownMenuItem<String>(
                                value: pit['id'],
                                child: Text(pit['keterangan'],
                                    style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPitId = value;
                                pitController.text = pitList.firstWhere(
                                    (pit) => pit['id'] == value)['keterangan'];
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'PIT harus dipilih';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'SHIFT',
                              labelStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.white, width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            dropdownColor: Color(0xFF003366),
                            style: TextStyle(color: Colors.white),
                            icon: Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            value: selectedShiftId,
                            items: shiftList.map((shift) {
                              return DropdownMenuItem<String>(
                                value: shift['id'],
                                child: Text(shift['keterangan'],
                                    style: TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedShiftId = value;
                                shiftController.text = shiftList.firstWhere(
                                    (shift) =>
                                        shift['id'] == value)['keterangan'];
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Shift harus dipilih';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: dateController,
                                  readOnly: true,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Tanggal',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _selectDate,
                                      icon: Icon(Icons.calendar_today,
                                          color: Colors.white),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Tanggal harus diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: timeController,
                                  readOnly: true,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Waktu',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: _selectTime,
                                      icon: Icon(Icons.access_time,
                                          color: Colors.white),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Waktu harus diisi';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Checklist Items Section
                Text(
                  'Daftar Checklist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001932),
                  ),
                ),
                SizedBox(height: 16),
                ...checklistItems.entries
                    .map((entry) => _buildChecklistItem(entry.key, entry.value))
                    .toList(),

                // Additional Notes Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Tambahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001932),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: additionalNotesController,
                          decoration: InputDecoration(
                            labelText: 'Catatan Tambahan',
                            hintText: 'Masukkan catatan tambahan (opsional)',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF001932), width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Diketahui',
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(0xFF001932), width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          value: selectedDiketahuiNik,
                          items: diketahuiList.map((user) {
                            return DropdownMenuItem<String>(
                              value: user['nik'],
                              child: Text(user['nama']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDiketahuiNik = value;
                              diketahuiController.text =
                                  diketahuiList.firstWhere(
                                      (user) => user['nik'] == value)['nama'];
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Diketahui harus dipilih';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF001932),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Color(0xFF001932).withOpacity(0.3),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Menyimpan...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Simpan Data',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
