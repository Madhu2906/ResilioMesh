//  https://13jr54g7-8080.inc1.devtunnels.ms/api/users/update-device

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'privacy_policy_screen.dart';
import 'news_detail_screen.dart';
import 'notification_store.dart';
import 'notifications_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_screen.dart';
import 'emergency_contacts_screen.dart';
import 'safety_tips_screen.dart';
import 'disaster_map_screen.dart';
import 'disaster_details_screen.dart';
import 'about_us_screen.dart';
import 'dart:convert';
import 'live_weather_screen.dart';

// Global Navigation Key to handle notification taps anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global Audio Player for Emergency Siren
final AudioPlayer _sirenAudioPlayer = AudioPlayer();

// Plugin instance for local heads-up banners
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Android High Importance Channel
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID matching Spring Boot & AndroidManifest
  'High Importance Notifications',
  description: 'This channel is used for high priority disaster alerts.',
  importance: Importance.max,
  playSound: true,
);

// Trigger Siren Sound & Camera Flash Strobe Effect
Future<void> _triggerEmergencyHardwareEffects() async {
  try {
    // 1. Play Emergency Siren Audio
    await _sirenAudioPlayer.stop();
    await _sirenAudioPlayer.play(AssetSource('siren.mp3'));
  } catch (e) {
    debugPrint("Error playing siren sound: $e");
  }

  // 2. Flash Camera Strobe Light (Flashes 6 times)
  try {
    bool isTorchAvailable = await TorchLight.isTorchAvailable();
    if (isTorchAvailable) {
      for (int i = 0; i < 6; i++) {
        await TorchLight.enableTorch();
        await Future.delayed(const Duration(milliseconds: 250));
        await TorchLight.disableTorch();
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
  } catch (e) {
    debugPrint("Torch light hardware error: $e");
  }
}

// Top-level background notification handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Trigger hardware effects in background
  _triggerEmergencyHardwareEffects();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Android Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        try {
          Map<String, dynamic> data = jsonDecode(response.payload!);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(
                title: data['title'] ?? 'Emergency Alert',
                body: data['body'] ?? 'No details available.',
              ),
            ),
          );
        } catch (e) {
          debugPrint("Error parsing payload: $e");
        }
      }
    },
  );

  // Register channel on Android system
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  runApp(const ResilioMeshApp());
}

class ResilioMeshApp extends StatefulWidget {
  const ResilioMeshApp({super.key});

  @override
  State<ResilioMeshApp> createState() => _ResilioMeshAppState();
}

class _ResilioMeshAppState extends State<ResilioMeshApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFCMAndLocation();
      _setupNotificationNavigation();
    });
  }

  // Handle opening NewsDetailScreen when tapping background / closed notifications
  Future<void> _setupNotificationNavigation() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    String title =
        message.data['title'] ??
        message.notification?.title ??
        'Emergency Alert';
    String body =
        message.data['body'] ??
        message.notification?.body ??
        'No details available.';

    NotificationStore.instance.addNotification(
      title,
      body,
    ); // SAVE NOTIFICATION

    // Trigger siren and flash effects on notification tap
    _triggerEmergencyHardwareEffects();

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(title: title, body: body),
      ),
    );
  }

  Future<void> _setupFCMAndLocation() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint("Notification permissions denied");
        return;
      }

      // 🔔 SUBSCRIBE TO FCM BROADCAST TOPIC FOR SOS ALERTS
      await messaging.subscribeToTopic('sos-alerts');
      debugPrint("🔔 Subscribed device to FCM topic: sos-alerts");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String? token = await messaging.getToken();
      debugPrint("==================================================");
      debugPrint("MY FCM TOKEN: $token");
      debugPrint("==================================================");

      if (token != null) {
        await _sendTokenAndLocationToBackend(
          token,
          position.latitude,
          position.longitude,
        );
      }

      // Foreground Message Handler: Trigger local popup banner, siren, flash & save to store
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Received message in foreground: ${message.messageId}");
        RemoteNotification? notification = message.notification;

        String title =
            message.data['title'] ?? notification?.title ?? 'Emergency Alert';
        String body =
            message.data['body'] ??
            notification?.body ??
            'No details available.';

        // 1. Save notification to store so it shows up in NotificationsScreen (Bell Icon)
        NotificationStore.instance.addNotification(title, body);

        // 2. Trigger Flash Light Strobe & Siren Audio Effect
        _triggerEmergencyHardwareEffects();

        // 3. Trigger heads-up notification popup banner
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode({'title': title, 'body': body}),
        );
      });
    } catch (e) {
      debugPrint("Error registering device: $e");
    }
  }

  Future<void> _sendTokenAndLocationToBackend(
    String token,
    double lat,
    double lon,
  ) async {
    final url = Uri.parse('http://10.0.2.2:8080/api/users/update-device');

    try {
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcmToken': token,
          'latitude': lat,
          'longitude': lon,
        }),
      );
    } catch (e) {
      debugPrint("Failed to send token to Spring Boot API: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ResilioMesh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFFFF5252),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// TRICOLOR DISASTER RESPONSE LOGO
// ==========================================
class IndianDisasterLogo extends StatelessWidget {
  final double size;

  const IndianDisasterLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF9933),
                width: size * 0.05,
              ),
            ),
          ),
          Container(
            width: size * 0.90,
            height: size * 0.90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: size * 0.03),
            ),
          ),
          Container(
            width: size * 0.84,
            height: size * 0.84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF138808),
                width: size * 0.05,
              ),
            ),
          ),
          Container(
            width: size * 0.74,
            height: size * 0.74,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF8FAFC),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  size: size * 0.35,
                  color: const Color(0xFFFF9933),
                ),
                SizedBox(height: size * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: size * 0.16,
                      color: const Color(0xFFFF9933),
                    ),
                    Icon(
                      Icons.bolt_rounded,
                      size: size * 0.16,
                      color: const Color(0xFF000080),
                    ),
                    Icon(
                      Icons.add_moderator_rounded,
                      size: size * 0.16,
                      color: const Color(0xFF138808),
                    ),
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

// ==========================================
// SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _navigateToHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const IndianDisasterLogo(size: 160),
              const SizedBox(height: 28),
              const Text(
                'ResilioMesh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D47A1),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '(Disaster Management Department)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF546E7A),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 30.0),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF5252),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOME SCREEN
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardContent(),
    const DisasterMapScreen(),
    const SosScreen(),
    const Center(child: Text("Helpline Page")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 3) {
            makePhoneCall('8369732553');
          } else {
            setState(() => _currentIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFF5252),
        unselectedItemColor: const Color(0xFF9E9E9E),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked, color: Colors.redAccent),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call_rounded),
            label: 'Helpline',
          ),
        ],
      ),
    );
  }
}

// Helper function to launch the phone dialer
Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    debugPrint('Could not launch phone dialer for $phoneNumber');
  }
}

// ==========================================
// DASHBOARD CONTENT
// ==========================================
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFFF5252),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const Text(
                    'ResilioMesh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Bell Icon with Live Notification Counter
                  AnimatedBuilder(
                    animation: NotificationStore.instance,
                    builder: (context, child) {
                      final count =
                          NotificationStore.instance.notifications.length;

                      return Badge(
                        isLabelVisible: count > 0,
                        label: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.black,
                        child: IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xFFFF5252),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'DASHBOARD',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF334155),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      DashboardItem(
                        icon: Icons.wb_sunny_outlined,
                        label: 'Live\nWeather',
                        iconColor: Color(0xFFFF9800),
                        onTap: () {
                          // Navigates to the Live Weather screen when the dashboard card is clicked
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LiveWeatherScreen(),
                            ),
                          );
                        },
                      ),
                      DashboardItem(
                        icon: Icons.grain_outlined,
                        label: 'IMD\nForecast',
                        iconColor: Color(0xFF9C27B0),
                      ),
                      DashboardItem(
                        icon: Icons.phone_in_talk_outlined,
                        label: 'Emergency\nContact',
                        iconColor: const Color(0xFFF44336),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmergencyContactsScreen(),
                            ),
                          );
                        },
                      ),

                      DashboardItem(
                        icon: Icons.add_moderator_outlined,
                        label: 'Safety\nTips',
                        iconColor: Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SafetyTipsScreen(),
                            ),
                          );
                        },
                      ),
                      DashboardItem(
                        icon: Icons.assignment_outlined,
                        label: "Do's /\nDon't",
                        iconColor: Color(0xFF673AB7),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DosDontsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  const DashboardItem({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: iconColor.withAlpha(26),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// APP DRAWER
// ==========================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const IndianDisasterLogo(size: 100),
          const SizedBox(height: 20),
          const Divider(height: 1, indent: 20, endIndent: 20),
          const SizedBox(height: 10),
          _buildDrawerTile(Icons.home_outlined, 'Home', () {
            Navigator.pop(context);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }),
          _buildDrawerTile(Icons.info_outline_rounded, 'About Us', () {
            Navigator.pop(context);
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => AboutUsScreen()));
          }),
          _buildDrawerTile(Icons.notifications_none_rounded, 'Alert', () {}),
          _buildDrawerTile(Icons.privacy_tip_outlined, 'Privacy Policy', () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            );
          }),
          _buildDrawerTile(Icons.share_outlined, 'Share App', () {}),
          _buildDrawerTile(Icons.star_outline_rounded, 'Rate Us', () {}),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 24.0),
            child: Text(
              'Version 1.0.2',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF34495E), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2C3E50),
        ),
      ),
      onTap: onTap,
    );
  }
}
// ==========================================
// LIVE WEATHER SCREEN (Cities + Nearby Locations)
// ==========================================
class LiveWeatherScreen extends StatefulWidget {
  const LiveWeatherScreen({super.key});

  @override
  State<LiveWeatherScreen> createState() => _LiveWeatherScreenState();
}

class _LiveWeatherScreenState extends State<LiveWeatherScreen> {
  // Red & White Theme Colors
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color lightRedBg = Color(0xFFFFEBEE);
  static const Color cardBorderColor = Color(0xFFE0E0E0);

  // 25 Dynamic Locations combining Major Cities & Nearby Localities/Wards
  final List<String> _indiaLocations = [
    'Mumbai - Kurla West',
    'Mumbai - Bandra East',
    'Mumbai - Andheri West',
    'Mumbai - Colaba',
    'New Delhi - Connaught Place',
    'New Delhi - Dwarka',
    'Bengaluru - Indiranagar',
    'Bengaluru - Whitefield',
    'Kolkata - Salt Lake',
    'Kolkata - Park Street',
    'Chennai - T. Nagar',
    'Chennai - Velachery',
    'Hyderabad - Banjara Hills',
    'Hyderabad - Hitec City',
    'Ahmedabad - Satellite',
    'Pune - Koregaon Park',
    'Pune - Hinjewadi',
    'Jaipur - Malviya Nagar',
    'Lucknow - Hazratganj',
    'Nagpur - Civil Lines',
    'Indore - Vijay Nagar',
    'Patna - Boring Road',
    'Bhopal - MP Nagar',
    'Visakhapatnam - Beach Road',
    'Srinagar - Lal Chowk',
  ];

  String _selectedLocation = 'Mumbai - Kurla West';
  bool _isLoading = false;

  Map<String, dynamic> _weatherData = {
    'station': 'Kurla Local Station Node',
    'temp': '28.5° C',
    'rain': '0.00 mm',
    'wind': '10.2 km/h',
    'humidity': '85%',
    'pressure': '1008.2 hPa',
    'rain1hr': '0mm',
    'rain3hr': '0.2mm',
    'rain6hr': '0.5mm',
    'rain24hr': '4.1mm',
  };

  // GPS Live Location Fetcher
  Future<void> _requestUserLiveLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = 'GPS: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        _weatherData = {
          'station': 'Local GPS Sensor Node',
          'temp': '29.1° C',
          'rain': '0.10 mm',
          'wind': '8.5 km/h',
          'humidity': '82%',
          'pressure': '1006.5 hPa',
          'rain1hr': '0.1mm',
          'rain3hr': '0.4mm',
          'rain6hr': '0.8mm',
          'rain24hr': '5.2mm',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _onLocationChanged(String? newLocation) {
    if (newLocation != null) {
      setState(() {
        _selectedLocation = newLocation;
        int hash = newLocation.hashCode.abs();
        _weatherData = {
          'station': '${newLocation.split('-')[0].trim()} Ward Node',
          'temp': '${(24 + (hash % 9)).toStringAsFixed(1)}° C',
          'rain': '${(hash % 3 == 0) ? '1.20' : '0.00'} mm',
          'wind': '${(5 + (hash % 12)).toStringAsFixed(1)} km/h',
          'humidity': '${70 + (hash % 25)}%',
          'pressure': '${1000 + (hash % 15)}.4 hPa',
          'rain1hr': '${hash % 2}mm',
          'rain3hr': '${(hash % 4) * 0.2}mm',
          'rain6hr': '${(hash % 5) * 0.4}mm',
          'rain24hr': '${(hash % 10) * 0.9}mm',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: const Text(
          'Live Weather',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Curve Container with Red Theme
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Clickable Live Weather Card Header triggering GPS
                  GestureDetector(
                    onTap: _requestUserLiveLocation,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.wb_sunny_rounded,
                        size: 30,
                        color: primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap icon for Live GPS Weather',
                    style: TextStyle(fontSize: 10, color: lightRedBg),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Content Padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Selection (Cities + Nearby Locations)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_pin, color: primaryRed, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _indiaLocations.contains(_selectedLocation) ? _selectedLocation : null,
                              hint: Text(_selectedLocation, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                              items: _indiaLocations.map((String location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(location, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                );
                              }).toList(),
                              onChanged: _onLocationChanged,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Weather Station Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weather Station', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(_weatherData['station'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Last 15 minutes data', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('View on Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryRed)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Data Metrics Section
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorderColor),
                        ),
                        child: Column(
                          children: [
                            _buildMetricRow('Temp', _weatherData['temp']),
                            const Divider(height: 12, color: cardBorderColor),
                            _buildMetricRow('Rain', _weatherData['rain']),
                            const Divider(height: 12, color: cardBorderColor),
                            _buildMetricRow('Wind', _weatherData['wind']),
                            const Divider(height: 12, color: cardBorderColor),
                            _buildMetricRow('Humidity', _weatherData['humidity']),
                            const Divider(height: 12, color: cardBorderColor),
                            _buildMetricRow('Pressure', _weatherData['pressure']),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withOpacity(0.7),
                            child: const Center(
                              child: CircularProgressIndicator(color: primaryRed, strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Center(
                    child: Text('Rainfall (Most Recent)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54)),
                  ),

                  const SizedBox(height: 8),

                  // Rainfall Intervals
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRainfallColumn('1 hr', _weatherData['rain1hr']),
                        _buildVerticalDivider(),
                        _buildRainfallColumn('3 hr', _weatherData['rain3hr']),
                        _buildVerticalDivider(),
                        _buildRainfallColumn('6 hr', _weatherData['rain6hr']),
                        _buildVerticalDivider(),
                        _buildRainfallColumn('24 hr', _weatherData['rain24hr']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildRainfallColumn(String timeLabel, String amount) {
    return Column(
      children: [
        Text(timeLabel, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: cardBorderColor,
    );
  }
}