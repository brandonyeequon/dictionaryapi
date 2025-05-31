import 'package:flutter/material.dart';
import 'dictionary_screen.dart';
import 'enhanced_learn_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // Keys for nested navigators to preserve bottom navigation
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];
  // Root screens for each tab
  final List<Widget> _screens = const [
    DictionaryScreen(),
    EnhancedLearnScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final NavigatorState currentNav = _navigatorKeys[_currentIndex].currentState!;
        if (currentNav.canPop()) {
          currentNav.pop();
          return false;
        }
        // If on first tab, allow back; else go to first tab
        if (_currentIndex != 0) {
          setState(() { _currentIndex = 0; });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jisho Dictionary'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'logout') {
                  await AuthService().signOut();
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        const Text('Sign Out'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Stack(
          children: List.generate(_screens.length, (index) {
            return Offstage(
              offstage: _currentIndex != index,
              child: Navigator(
                key: _navigatorKeys[index],
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (_) => _screens[index],
                    settings: settings,
                  );
                },
              ),
            );
          }),
        ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Dictionary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Learn',
          ),
        ],
        ),
      ),
    );
  }
}