import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/theme/app_theme.dart';
import 'package:calwatt/screens/dashboard_screen.dart';
import 'package:calwatt/screens/appliances_screen.dart';
import 'package:calwatt/screens/analytics_screen.dart';
import 'package:calwatt/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalWattApp());
}

/// Root widget for the CalWatt application.
///
/// Sets up provider state management and Material 3 theme.
class CalWattApp extends StatelessWidget {
  const CalWattApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: MaterialApp(
        title: 'CalWatt',
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}

/// Home page with bottom navigation bar and screen switching logic.
///
/// Displays the selected screen based on the current tab and provides
/// navigation through a bottom navigation bar.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initializes the app state with sample appliances and settings.
  Future<void> _initializeApp() async {
    final appState = context.read<AppState>();
    await appState.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (!appState.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Select screen based on current tab
          return IndexedStack(
            index: appState.currentTab,
            children: const [
              DashboardScreen(),
              AppliancesScreen(),
              AnalyticsScreen(),
              SettingsScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<AppState>(
        builder: (context, appState, _) {
          return BottomNavigationBar(
            currentIndex: appState.currentTab,
            onTap: (index) {
              context.read<AppState>().setCurrentTab(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.devices_outlined),
                activeIcon: Icon(Icons.devices),
                label: 'Appliances',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined),
                activeIcon: Icon(Icons.analytics),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          );
        },
      ),
    );
  }
}
