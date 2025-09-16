import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:survey/pages/kkh/index.dart';
import 'package:survey/pages/notification_page.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// import 'package:survey/models/models.dart';
// import '../services/auth_service.dart';

part 'shared_pref_keys.dart';
part 'splash_screen.dart';
part 'login_page.dart';
part 'main_page.dart';
part 'klkh/fuelStation/index.dart';
part 'klkh/fuelStation/insert.dart';
part 'klkh/fuelStation/edit.dart';
part 'klkh/fuelStation/show.dart';
part 'aktivitas_page.dart';

const String baseUrl = "http://36.67.119.212:9014";
const String baseUrl2 = "http://36.67.119.212:9011";

String formatTanggal(String? rawDate) {
  if (rawDate == null || rawDate.isEmpty) return '-';
  try {
    final date = DateTime.parse(rawDate);
    return DateFormat('d MMMM y', 'id_ID').format(date);
  } catch (e) {
    return rawDate;
  }
}

String formatWaktu(String? rawTime) {
  if (rawTime == null || rawTime.isEmpty) return '-';
  try {
    // Hapus bagian nanodetik jika ada (setelah titik)
    final cleanTime = rawTime.split('.').first;
    final time = DateFormat('HH:mm:ss').parse(cleanTime);
    return DateFormat('HH.mm').format(time); // hasil: 09.26
  } catch (e) {
    return rawTime; // fallback jika format salah
  }
}
