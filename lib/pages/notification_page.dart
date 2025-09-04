import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survey/pages/pages.dart';

class NotifikasiPage extends StatefulWidget {
  @override
  _NotifikasiPageState createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  bool isLoading = false;
  List<Map<String, dynamic>> notifikasiList = [];

  @override
  void initState() {
    super.initState();

    // Animasi fade masuk
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Animasi loading (opacity naik turun)
    _loadingController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadingAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _fetchNotifikasiData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifikasiData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.get(
        Uri.parse('${baseUrl}/api/notification'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifikasiList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print("Error: $e");
      showErrorDialog("Gagal memuat notifikasi: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Error", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Color(0xFF001932))),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifikasiItem(Map<String, dynamic> item) {
    bool isRead = item['READ'] == "1";

    return GestureDetector(
      onTap: () async {
        // kalau belum dibaca, tandai sudah dibaca
        if (!isRead) {
          await _markAsRead(item['ID']);
        }

        // tampilkan modal detail notifikasi
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.notifications, color: Color(0xFF001932)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['TITLE'] ?? "Notifikasi",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF001932)),
                  ),
                ),
              ],
            ),
            content: Text(item['BODY'] ?? "-"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text("Tutup", style: TextStyle(color: Color(0xFF001932))),
              ),
            ],
          ),
        );

        // setelah modal ditutup, panggil fetch data ulang
        _fetchNotifikasiData();
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        color: isRead ? Colors.white : Colors.blue.shade50, // beda warna
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isRead ? Colors.grey : Color(0xFF001932),
            child: Icon(Icons.notifications, color: Colors.white),
          ),
          title: Text(
            item['TITLE'] ?? "Notifikasi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF001932),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(item['BODY'] ?? "-", style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPrefKeys.token);

      final response = await http.put(
        Uri.parse('${baseUrl}/api/read-notification/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          // update list lokal biar langsung berubah warna
          final index =
              notifikasiList.indexWhere((element) => element['ID'] == id);
          if (index != -1) {
            notifikasiList[index]['READ'] = "1";
          }
        });
        _fetchNotifikasiData();
      } else {
        print("Failed to update notification: ${response.body}");
      }
    } catch (e) {
      print("Error update read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title:
            Text("Notifikasi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF001932),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isLoading
            ? Center(
                child: Image.asset(
                  'assets/images/spinning-loading.gif',
                  width: 200,
                ),
              )
            : notifikasiList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey.shade400),
                        SizedBox(height: 16),
                        Text("Belum ada notifikasi",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchNotifikasiData,
                    color: Color(0xFF001932),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: notifikasiList.length,
                      itemBuilder: (_, i) =>
                          _buildNotifikasiItem(notifikasiList[i]),
                    ),
                  ),
      ),
    );
  }
}
