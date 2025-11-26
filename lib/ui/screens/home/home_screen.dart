import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:surakshith/data/providers/auth_provider.dart';
import 'package:surakshith/data/providers/client_provider.dart';
import 'package:surakshith/data/providers/project_provider.dart';
import 'package:surakshith/ui/screens/reports/reports_screen.dart';
import 'package:surakshith/ui/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Surakshith',
    'Reports',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // Sync all data from Firebase in background after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAllDataFromFirebase();
    });
  }

  // Sync clients and projects from Firebase
  Future<void> _syncAllDataFromFirebase() async {
    // Clients now use real-time Firestore listeners - no manual sync needed!
    // await clientProvider.syncClients(); // REMOVED - real-time sync now

    // Projects now use real-time Firestore listeners - no manual sync needed!
    // final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    // final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    // final clients = clientProvider.getAllClients();
    // final clientIds = clients.map((c) => c.id).toList();
    // await projectProvider.pullAllProjectsFromFirebase(clientIds); // REMOVED - real-time sync now
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _currentIndex == 2 ? const Color(0xFFF7F7F7) : Colors.white,
      appBar: _currentIndex == 2
          ? null // No AppBar for settings tab
          : AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF222222),
              title: Text(
                _titles[_currentIndex],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontSize: Platform.isIOS ? 20 : 22,
                ),
              ),
              actions: _currentIndex != 2
                  ? [
                      IconButton(
                        icon: const Icon(Icons.logout_outlined),
                        onPressed: _logout,
                        tooltip: 'Sign Out',
                      ),
                    ]
                  : null,
            ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: const Color(0xFFE91E63),
              unselectedItemColor: Colors.grey[600],
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: Platform.isIOS ? 11 : 12,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: Platform.isIOS ? 11 : 12,
              ),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 26),
                  activeIcon: Icon(Icons.home, size: 26),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assessment_outlined, size: 26),
                  activeIcon: Icon(Icons.assessment, size: 26),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 26),
                  activeIcon: Icon(Icons.settings, size: 26),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF6E40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Surakshith',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Streamline your audit process with ease',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Platform.isIOS ? 14 : 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildFeatureCard(
                icon: Icons.assessment_outlined,
                title: 'Create Reports',
                description: 'Generate comprehensive audit reports',
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.settings_outlined,
                title: 'Manage Data',
                description: 'Configure clients, projects, and audit settings',
                color: const Color(0xFF9C27B0),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                icon: Icons.cloud_sync_outlined,
                title: 'Cloud Sync',
                description: 'All your data backed up automatically',
                color: const Color(0xFF4CAF50),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: Platform.isIOS ? 12 : 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
