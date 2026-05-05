import 'package:flutter/material.dart';
import '../models/media_item.dart';
import 'dashboard_screen.dart';
import 'activity_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart';
import '../widgets/search_api_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<MediaItem> activeItems = [];

  void _triggerUpdate() {
    setState(() {});
  }

  void _openQuickAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => SearchApiDialog(
        onItemAdded: (newItem) {
          setState(() {
            // --- FIX: DUPLICATE CHECKER & MULTIPLIER LOGIC ---
            int existingIndex = activeItems.indexWhere((item) => item.title == newItem.title);

            if (existingIndex != -1) {
              var existing = activeItems[existingIndex];
              if (newItem.status == 'Completed') {
                existing.completedCount++; // Level up the multiplier!
                existing.status = 'Completed';
                existing.progress = existing.total;
                existing.isWatchLater = false;
              } else if (newItem.isWatchLater) {
                existing.isWatchLater = true;
              }
              // Move it to the top of the list
              activeItems.removeAt(existingIndex);
              activeItems.insert(0, existing);
            } else {
              activeItems.insert(0, newItem);
            }
          });
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return DashboardScreen(activeItems: activeItems, onUpdate: _triggerUpdate);
      case 1: return ActivityScreen(allItems: activeItems, onUpdate: _triggerUpdate);
      case 2: return const ScheduleScreen();
    // Passing activeItems to the Profile so Top 5 works!
      case 3: return ProfileScreen(activeItems: activeItems);
      default: return const Center(child: Text('Error'));
    }
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00).withOpacity(0.15) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? const Color(0xFFFF6B00) : Colors.grey[400], size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 75, width: 75,
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFFC300)]),
          boxShadow: [BoxShadow(color: const Color(0xFFFF6B00).withOpacity(0.5), blurRadius: 25, offset: const Offset(0, 10))],
        ),
        child: FloatingActionButton(
          onPressed: _openQuickAddDialog,
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: const Icon(Icons.add_rounded, size: 40, color: Colors.white),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 15))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.dashboard_rounded, 0),
            _buildNavItem(Icons.local_activity_rounded, 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.calendar_month_rounded, 2),
            _buildNavItem(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }
}