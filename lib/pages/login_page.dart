part of 'pages.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nikController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool rememberMe = true; // Changed to true by default
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _loadingTimer;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    nikController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Future<void> login() async {
  //   if (nikController.text.isEmpty || passwordController.text.isEmpty) {
  //     showErrorDialog('NIK dan Password harus diisi!');
  //     return;
  //   }

  //   setState(() {
  //     isLoading = true;
  //   });

  //   _loadingTimer = Timer(Duration(seconds: 10), () {
  //     if (mounted && isLoading) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //       showErrorDialog('Silakan coba lagi.');
  //     }
  //   });

  //   try {
  //     final response = await http.post(
  //       Uri.parse('${baseUrl}/api/login'),
  //       headers: {
  //         'Accept': 'application/json',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         'nik': nikController.text,
  //         'password': passwordController.text,
  //       }),
  //     ).timeout(Duration(seconds: 8));

  //     final responseData = jsonDecode(response.body);

  //     if (response.statusCode == 200) {
  //       // Simpan token dan user data ke SharedPreferences
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString(SharedPrefKeys.token, responseData['token']);
  //       await prefs.setString(
  //           SharedPrefKeys.user, jsonEncode(responseData['user']));

  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => MainPage(
  //               responseMessage: responseData['message'] ?? 'Login berhasil'),
  //         ),
  //       );
  //     } else {
  //       showErrorDialog(responseData['message'] ?? 'Login gagal');
  //     }
  //   } catch (e) {
  //     showErrorDialog('Terjadi kesalahan: $e');
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> login() async {
    if (nikController.text.isEmpty || passwordController.text.isEmpty) {
      showErrorDialog('NIK dan Password harus diisi!');
      return;
    }

    setState(() {
      isLoading = true;
    });

    _loadingTimer = Timer(Duration(seconds: 10), () {
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
        });
        showErrorDialog('Silakan coba lagi.');
      }
    });

    try {
      final response = await http
          .post(
            Uri.parse('${baseUrl}/api/login'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'nik': nikController.text,
              'password': passwordController.text,
            }),
          )
          .timeout(Duration(seconds: 8));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan token dan user data ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(SharedPrefKeys.token, responseData['token']);
        await prefs.setString(
            SharedPrefKeys.user, jsonEncode(responseData['user']));

        // 🔹 Ambil FCM token device
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          // 🔹 Kirim FCM token ke backend untuk update tabel users
          await http.put(
            Uri.parse('${baseUrl}/api/fcm-token'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${responseData['token']}',
            },
            body: jsonEncode({
              'fcm_token': fcmToken,
            }),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(
                responseMessage: responseData['message'] ?? 'Login berhasil'),
          ),
        );
      } else {
        showErrorDialog(responseData['message'] ?? 'Login gagal');
      }
    } catch (e) {
      // showErrorDialog('Terjadi kesalahan: $e');
      showErrorDialog('Terjadi kesalahan: Jaringan tidak stabil');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
              Text('Info', style: TextStyle(color: Colors.red)),
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

  void showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Lupa Password'),
          content: Text('Untuk mengganti password melalui aplikasi POKA'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Illustration
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/batik.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Color(0xFF001932)
                            .withOpacity(0.5), // bisa sesuaikan transparansinya
                        BlendMode.srcOver,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Corak latar transparan (hiasan)
                      Positioned(
                        top: 40,
                        left: 20,
                        child: Container(
                          width: 60,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        right: 30,
                        child: Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 50,
                        child: Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Main illustration
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image / Illustration
                            Container(
                              width: 200,
                              height: 150,
                              child: Image.asset(
                                'assets/images/splash.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Optional Title
                            // const Text(
                            //   'PlannER (Planning E-Report)',
                            //   style: TextStyle(
                            //     color: Colors.white,
                            //     fontSize: 14,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            //   textAlign: TextAlign.center,
                            // ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Login Form
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Login Title
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001932), // Changed to primary color
                        ),
                      ),
                      SizedBox(height: 30),

                      // NIK Field
                      Text(
                        'NIK / NRP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: nikController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan NIK / NRP anda',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF001932), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password anda',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Color(0xFF001932), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Remember me and Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe, // Now using the variable
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value!;
                                  });
                                },
                                activeColor: Color(0xFF001932), // Primary color
                              ),
                              Text(
                                'Ingat Saya!',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed:
                                showForgotPasswordDialog, // Updated to call the new dialog
                            child: Text(
                              'Lupa password?',
                              style: TextStyle(
                                color: Color(0xFF001932), // Primary color
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Login Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF001932), // Primary color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Masuk...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 40),

                      // Powered by
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: '© Powered by ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'IT',
                                style: TextStyle(
                                  color: Color(0xFF001932), // Primary color
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
