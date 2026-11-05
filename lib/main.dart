import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calwatt/providers/app_state.dart';
import 'package:calwatt/theme/app_theme.dart';
import 'package:calwatt/screens/dashboard_screen.dart';
import 'package:calwatt/screens/appliances_screen.dart';
import 'package:calwatt/screens/analytics_screen.dart';
import 'package:calwatt/screens/settings_screen.dart';
import 'package:calwatt/screens/simulation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalWattApp());
}

class CalWattApp extends StatelessWidget {
  const CalWattApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'CalWatt',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomePage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  static const _screens = [
    DashboardScreen(),
    AppliancesScreen(),
    SimulationScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
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
      icon: Icon(Icons.bar_chart_outlined),
      activeIcon: Icon(Icons.bar_chart),
      label: 'Simulate',
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
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (!appState.isInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, size: 48, color: AppTheme.primaryColor(context)),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: appState.currentTab,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: appState.currentTab,
            onTap: (index) => context.read<AppState>().setCurrentTab(index),
            items: _navItems,
          ),
        );
      },
    );
  }
}
