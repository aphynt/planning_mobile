part of 'pages.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPrefKeys.token);

    await Future.delayed(Duration(seconds: 2)); // Delay untuk splash screen

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => token != null ? MainPage(responseMessage: '') : LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background3.jpg'), // Gambar latar belakang
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Lapisan overlay gelap (semi-transparan)
          Positioned.fill(
            child: Container(
              color: const Color.fromRGBO(0, 0, 0, 0.8), // ✅ INI PASTI BERFUNGSI
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(19, 230, 191, 191), // Hover putih
            ),
          ),
          // Konten splash screen
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Image.asset(
                    'assets/images/splash.png',
                    width: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                Column(
                  children: [
                    Image.asset(
                      'assets/images/sims.png',
                      width: 400,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Copyright © 2025 by IT Support',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}