import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cart_screen.dart'; // Ensure proper import
import 'account_screen.dart';
import 'package:food_truck_booking_app/screens/food_truck_selection_page_screen.dart';
import 'AdminScreen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int? userId;
  final bool isAdmin;

  const MainNavigationScreen({Key? key, this.userId, required this.isAdmin})
      : super(key: key);

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();

    if (widget.isAdmin) {
      // Admin-specific setup
      _screens = [const AdminScreen()];
      _navItems = []; // No navigation bar items for admin
    } else {
      // Regular user setup
      _screens = [
        const HomeScreen(),
        CartScreen(userId: widget.userId!),
        FoodTruckSelectionPage(userId: widget.userId!),
        AccountScreen(userId: widget.userId!),
      ];
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fastfood),
          label: 'Packages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Account',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAdmin) {
      // Admin-specific setup
      return const AdminScreen(); // No AppBar in MainNavigationScreen for Admin
    }

    // For regular users
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index < _screens.length) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: _navItems,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
