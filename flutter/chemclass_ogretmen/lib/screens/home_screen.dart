import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants.dart';
import '../providers/app_provider.dart';
import '../services/supabase_service.dart';
import 'students_screen.dart';
import 'attendance_screen.dart';
import 'scores_screen.dart';
import 'assignments_screen.dart';
import 'messages_screen.dart';
import 'gradebook_screen.dart';
import 'schedule_screen.dart';
import 'board_screen.dart';
import 'tools_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final _pages = const [
    StudentsScreen(),
    AttendanceScreen(),
    ScoresScreen(),
    AssignmentsScreen(),
    MessagesScreen(),
    GradebookScreen(),
    ScheduleScreen(),
    BoardScreen(),
    ToolsScreen(),
  ];

  final _navItems = const [
    _NavItem(Icons.people_outline, Icons.people, 'Sınıflar'),
    _NavItem(Icons.how_to_reg_outlined, Icons.how_to_reg, 'Yoklama'),
    _NavItem(Icons.star_outline, Icons.star, 'Puanlar'),
    _NavItem(Icons.assignment_outlined, Icons.assignment, 'Ödevler'),
    _NavItem(Icons.chat_outlined, Icons.chat, 'Mesajlar'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Not Defteri'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Program'),
    _NavItem(Icons.cast_outlined, Icons.cast, 'Tahta'),
    _NavItem(Icons.build_outlined, Icons.build, 'Araçlar'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appDataProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600) _buildRail(),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? _buildBottomNav()
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kSurface,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Icon(Icons.science, color: kAccent, size: 24),
          const SizedBox(width: 8),
          Text(
            'CHEMCLASS',
            style: TextStyle(
              color: kAccent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Öğretmen',
              style: TextStyle(color: kAccent, fontSize: 11),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: kTextSecondary, size: 20),
          tooltip: 'Çıkış Yap',
          onPressed: () => _confirmSignOut(),
        ),
      ],
    );
  }

  Widget _buildRail() {
    return NavigationRail(
      backgroundColor: kSurface,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(color: kAccent),
      selectedLabelTextStyle: TextStyle(color: kAccent, fontSize: 11),
      unselectedIconTheme: IconThemeData(color: kTextSecondary),
      unselectedLabelTextStyle: TextStyle(color: kTextSecondary, fontSize: 11),
      destinations: _navItems.map((item) => NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.selectedIcon),
        label: Text(item.label),
      )).toList(),
    );
  }

  Widget _buildBottomNav() {
    // Show only first 5 in bottom nav; rest accessible via drawer/menu
    return BottomNavigationBar(
      backgroundColor: kSurface,
      selectedItemColor: kAccent,
      unselectedItemColor: kTextSecondary,
      currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
      type: BottomNavigationBarType.fixed,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (i) {
        if (i == 4) {
          // Show more options
          _showMoreMenu();
        } else {
          setState(() => _selectedIndex = i);
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(_navItems[0].icon),
          activeIcon: Icon(_navItems[0].selectedIcon),
          label: _navItems[0].label,
        ),
        BottomNavigationBarItem(
          icon: Icon(_navItems[1].icon),
          activeIcon: Icon(_navItems[1].selectedIcon),
          label: _navItems[1].label,
        ),
        BottomNavigationBarItem(
          icon: Icon(_navItems[2].icon),
          activeIcon: Icon(_navItems[2].selectedIcon),
          label: _navItems[2].label,
        ),
        BottomNavigationBarItem(
          icon: Icon(_navItems[3].icon),
          activeIcon: Icon(_navItems[3].selectedIcon),
          label: _navItems[3].label,
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'Daha Fazla',
        ),
      ],
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: kTextSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ..._navItems.sublist(4).asMap().entries.map((e) => ListTile(
            leading: Icon(e.value.icon, color: kAccent),
            title: Text(e.value.label, style: TextStyle(color: kTextPrimary)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = e.key + 4);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Çıkış Yap', style: TextStyle(color: kTextPrimary)),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Çıkış Yap', style: TextStyle(color: kRed)),
          ),
        ],
      ),
    );
    if (ok == true) await SupabaseService.signOut();
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}
