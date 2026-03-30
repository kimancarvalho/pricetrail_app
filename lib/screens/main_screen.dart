import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'route/route_screen.dart';
import 'profile/profile_screen.dart';

/// Ecrã principal da app — contém o BottomNavigationBar
/// e gere a navegação entre os 4 tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = AppConstants.tabLists;

  String? _activeListId;
  String? _activeListName;

  //chamado pelo HomeScreen quando o utilizador clica numa lista. Faz duas coisas: define a lista ativa
  //E muda o tab para o Explore
  void _navigateToExplore(String listId, String listName) {
    setState(() {
      _activeListId = listId;
      _activeListName = listName;
      _currentIndex = AppConstants.tabExplore;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onNavigateToExplore: _navigateToExplore),
          ExploreScreen(
            // key força recriação quando a lista ativa muda
            key: ValueKey('$_activeListId-$_activeListName'),
            activeListId: _activeListId,
            activeListName: _activeListName,
          ),
          const RouteScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Route',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
