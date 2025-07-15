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
// import 'package:survey/models/models.dart';
// import '../services/auth_service.dart';

part 'shared_pref_keys.dart';
part 'splash_screen.dart';
part 'login_page.dart';
part 'main_page.dart';
part 'fuel_station_page.dart';
part 'klhh_page.dart';
part 'aktivitas_page.dart';

String baseUrl = "http://36.67.119.214:9013";
