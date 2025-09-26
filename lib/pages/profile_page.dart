part of 'pages.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Profile',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dengan background + card profil
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color.fromARGB(255, 255, 255, 255)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
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
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage("assets/profile.jpg"), 
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ahmad Fadillah",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Column(
                                      children: const [
                                        Text("150",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text("Followers",
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    Column(
                                      children: const [
                                        Text("4.8",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text("Rating",
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Daftar menu konten
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _MenuItem(title: "Design Basic"),
                _MenuItem(title: "Concepts & Models"),
                _MenuItem(title: "Data Analysis"),
                _MenuItem(title: "Prototyping"),
                _MenuItem(title: "Final Project"),
              ],
            ),
          ],
        ),
      ),

    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;

  const _MenuItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      onTap: () {},
    );
  }
}
