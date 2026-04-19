import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile.dart';
import 'oldtractor.dart';
import 'rotavator.dart';
import 'cultivator.dart';
import 'harrow.dart';
import 'reaper.dart';
import 'threshing.dart';
import 'loader.dart';
import 'trailer.dart';
import 'weeder.dart';
import 'dronelistpage.dart';
import 'SellEquipmentPage.dart';
import 'selldron.dart';
import 'weather.dart';
import 'my_tools.dart';
import 'my_cart.dart';
import 'my_drones.dart';
import 'request.dart';
import 'login_page.dart'; // Added import for login_page.dart

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late VideoPlayerController _controller;
  int _selectedIndex = 0;
  String userTaluka = '';
  String weatherInfo = '';
  double tempValue = 0;
  String descValue = '';
  double windValue = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/NewDrone.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.setVolume(0.0);
        _controller.setLooping(true);
        _controller.play();
      });
    fetchTaluka();
  }

  Future<void> fetchTaluka() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final email = user.email ?? '';

    final res = await Supabase.instance.client
        .from('Users')
        .select('taluka')
        .eq('email', email)
        .maybeSingle();

    if (res != null) {
      setState(() {
        userTaluka = res['taluka'] ?? '';
      });
      if (userTaluka.isNotEmpty) {
        fetchWeather(userTaluka);
      }
    }
  }

  Future<void> fetchWeather(String city) async {
    try {
      const apiKey = "c3db44df597bbe766d1306d5a756640c";
      final url =
          "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data["main"]["temp"];
        final desc = data["weather"][0]["description"];
        final wind = data["wind"]["speed"];
        setState(() {
          tempValue = temp.toDouble();
          descValue = desc.toString();
          windValue = wind.toDouble();
          weatherInfo =
              "${temp.toString()}°C, ${desc.toString()}, Wind: ${wind} m/s";
        });
      } else {
        setState(() {
          weatherInfo = "Weather not found";
        });
      }
    } catch (e) {
      setState(() {
        weatherInfo = "Error fetching weather";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchAndNavigate(String query) {
    final q = query.toLowerCase().trim();
    if (q.contains('tractor')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OldTractorPage()),
      );
    } else if (q.contains('mahindra tractor')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OldTractorPage()),
      );
    } else if (q.contains('rotavator')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RotavatorPage()),
      );
    } else if (q.contains('cultivator')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CultivatorPage()),
      );
    } else if (q.contains('harrow')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HarrowPage()),
      );
    } else if (q.contains('reaper')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReaperPage()),
      );
    } else if (q.contains('threshing')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ThreshingPage()),
      );
    } else if (q.contains('front loader')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoaderPage()),
      );
    } else if (q.contains('farm trailer')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrailerPage()),
      );
    } else if (q.contains('power weeder')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeederPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No matching equipment found for "$query"')),
      );
    }
    _searchController.clear();
  }

  Future<void> _showLogoutConfirmation() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Logout first
                await Supabase.instance.client.auth.signOut();

                // Close dialog
                Navigator.of(context, rootNavigator: true).pop();

                // Navigate to LoginPage and remove all previous routes
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.withOpacity(0.2),
                    Colors.greenAccent.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Text(
                'AgroSmart Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud, color: Colors.white),
              title: const Text(
                'Weather',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeatherPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 55, 86, 118),
                  Color.fromARGB(255, 9, 14, 19),
                  Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomRight,
              ),
            ),
            child: _selectedIndex == 2
                ? _buildMoreOptions()
                : _buildMainContent(),
          ),
          // Logout icon
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 28),
              onPressed: _showLogoutConfirmation,
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white54,
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OldTractorPage()),
            );
          } else if (index == 3) {
            final user = Supabase.instance.client.auth.currentUser;
            final email = user?.email ?? '';
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Profile(email: email)),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'Old Tractor',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'More'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF1C1C1E), const Color(0xFF2C2C2E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    /// BRAND NAME
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        /// Soft depth shadow text
                        Text(
                          "AgroSmart",
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 5,
                            color: Colors.black.withOpacity(0.4),
                          ),
                        ),

                        /// Main metallic text
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFE6E6E6),
                              Color(0xFFFFFFFF),
                              Color(0xFF9E9E9E),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            "AgroSmart",
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    /// Premium Animated-Style Divider (Static Smooth Look)
                    Container(
                      height: 2.5,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey.shade500,
                            Colors.white70,
                            Colors.grey.shade500,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// Tagline (Refined)
                    Text(
                      "Smart Farming • Modern Technology",
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.2,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (userTaluka.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WeatherPage()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny,
                          size: 48,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${tempValue.toStringAsFixed(1)}°C",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              descValue.isNotEmpty ? descValue : weatherInfo,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              "Wind: ${windValue.toString()} m/s | $userTaluka",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: _searchAndNavigate,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search Equipments..',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white70),
                    onPressed: () {
                      _searchAndNavigate(_searchController.text);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AbsorbPointer(
                              absorbing: true,
                              child: VideoPlayer(_controller),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const DroneListPage(),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.greenAccent,
                                        Colors.greenAccent.withOpacity(0.7),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent.withOpacity(
                                          0.5,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "Book Drone Now",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  DashboardItem(
                    title: 'Tractor',
                    imagePath: 'assets/images/trac.jpg',
                    color: Color.fromARGB(255, 5, 9, 9),
                  ),
                  DashboardItem(
                    title: 'Rotavator',
                    imagePath: 'assets/images/rotavator.png',
                    color: Color.fromARGB(255, 4, 7, 7),
                  ),
                  DashboardItem(
                    title: 'Cultivator',
                    imagePath: 'assets/images/cultivator.jpg',
                    color: Color.fromARGB(255, 8, 7, 6),
                  ),
                  DashboardItem(
                    title: 'Harrow',
                    imagePath: 'assets/images/harrow1.png',
                    color: Color.fromARGB(255, 7, 9, 10),
                  ),
                  DashboardItem(
                    title: 'Reaper',
                    imagePath: 'assets/images/repear.jpg',
                    color: Color.fromRGBO(9, 10, 11, 1),
                  ),
                  DashboardItem(
                    title: 'Threshing Machine',
                    imagePath: 'assets/images/threching1.jpg',
                    color: Color.fromRGBO(6, 7, 10, 1),
                  ),
                  DashboardItem(
                    title: 'Front Loader',
                    imagePath: 'assets/images/front1.jpg',
                    color: Color.fromRGBO(3, 4, 5, 1),
                  ),
                  DashboardItem(
                    title: 'Farm Trailer',
                    imagePath: 'assets/images/trailer1.jpg',
                    color: Color.fromARGB(255, 8, 6, 2),
                  ),
                  DashboardItem(
                    title: 'Power Weeder',
                    imagePath: 'assets/images/power1.jpg',
                    color: Color.fromARGB(255, 9, 0, 3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptions() {
    final options = [
      {
        'title': 'Sell My Equipment',
        'icon': FontAwesomeIcons.tractor,
        'color': const Color.fromARGB(255, 0, 1, 1),
      },
      {
        'title': 'Book Drone service',
        'icon': Icons.flight_takeoff,
        'color': const Color.fromARGB(255, 0, 1, 1),
      },
      {
        'title': 'Register Drone Service',
        'icon': FontAwesomeIcons.helicopter,
        'color': const Color.fromARGB(255, 91, 140, 189),
      },
      {
        'title': 'My Equipments',
        'icon': FontAwesomeIcons.tools,
        'color': const Color.fromARGB(255, 91, 140, 189),
      },
      {
        'title': 'Favorites',
        'icon': FontAwesomeIcons.solidHeart,
        'color': const Color.fromARGB(255, 114, 180, 245),
      },
      {
        'title': 'Drone Request',
        'icon': FontAwesomeIcons.solidEnvelope,
        'color': const Color.fromARGB(255, 114, 180, 245),
      },
      {
        'title': 'My Drones',
        'icon': FontAwesomeIcons.clipboardList,
        'color': const Color.fromARGB(255, 114, 180, 245),
      },
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final item = options[index];
          return InkWell(
            onTap: () {
              if (item['title'] == 'Sell My Equipment') {
                final user = Supabase.instance.client.auth.currentUser;
                final email = user?.email ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SellEquipmentPage(email: email),
                  ),
                );
              } else if (item['title'] == 'Register Drone Service') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SellDronPage()),
                );
              } else if (item['title'] == 'My Drones') {
                final user = Supabase.instance.client.auth.currentUser;
                final email = user?.email ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyDronesPage(userEmail: email),
                  ),
                );
              } else if (item['title'] == 'Book Drone service') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DroneListPage()),
                );
              } else if (item['title'] == 'My Equipments') {
                final user = Supabase.instance.client.auth.currentUser;
                final email = user?.email ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyToolsPage(userEmail: email),
                  ),
                );
              } else if (item['title'] == 'Drone Request') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestPage()),
                );
              } else if (item['title'] == 'Favorites') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyCartPage()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['title']} clicked!'),
                    backgroundColor: item['color'] as Color,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item['color'] as Color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (item['color'] as Color).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 40,
                    color: item['color'] as Color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color color;
  final String? imagePath;

  const DashboardItem({
    super.key,
    required this.title,
    this.icon,
    required this.color,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              if (title == 'Tractor')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OldTractorPage()),
                );
              if (title == 'Rotavator')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RotavatorPage()),
                );
              if (title == 'Cultivator')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CultivatorPage()),
                );
              if (title == 'Harrow')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HarrowPage()),
                );
              if (title == 'Reaper')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReaperPage()),
                );
              if (title == 'Threshing Machine')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThreshingPage()),
                );
              if (title == 'Front Loader')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoaderPage()),
                );
              if (title == 'Farm Trailer')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrailerPage()),
                );
              if (title == 'Power Weeder')
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeederPage()),
                );
            },
            child: imagePath != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(imagePath!, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) Icon(icon, size: 36, color: color),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
