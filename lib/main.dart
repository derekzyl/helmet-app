import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/ble_provision_service.dart';
import 'screens/home_cockpit_screen.dart';
import 'screens/ble_pairing_screen.dart';
import 'screens/ride_history_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  await BleProvisionService.init();
  ApiService.connectWebSocket();
  runApp(const SmartHelmetApp());
}

class SmartHelmetApp extends StatelessWidget {
  const SmartHelmetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'HelmGuard',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeCockpitScreen(),
    BlePairingScreen(),
    RideHistoryScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: 'Cockpit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching),
            label: 'BLE Pair',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
