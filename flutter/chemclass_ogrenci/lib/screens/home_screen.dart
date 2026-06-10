import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/constants.dart';
import '../providers/session_provider.dart';
import 'score_screen.dart';
import 'assignments_screen.dart';
import 'messages_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  static const _tabs = [
    ScoreScreen(),
    AssignmentsScreen(),
    MessagesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider)!;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.rajdhani(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5),
                children: const [
                  TextSpan(
                      text: 'CHEM', style: TextStyle(color: kTextPrimary)),
                  TextSpan(text: 'CLASS', style: TextStyle(color: kAccent)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.name,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    session.className,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: kTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded,
                color: kTextSecondary, size: 20),
            tooltip: 'Çıkış',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sekme menüsü (üstte - klavye açıkken kapanmaması için)
          Container(
            decoration: const BoxDecoration(
              color: kSurface,
              border: Border(bottom: BorderSide(color: kSurface2)),
            ),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Puanım',
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _NavItem(
                  icon: Icons.assignment_rounded,
                  label: 'Ödevler',
                  active: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _NavItem(
                  icon: Icons.chat_rounded,
                  label: 'Mesajlar',
                  active: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
          Expanded(child: IndexedStack(index: _tab, children: _tabs)),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Çıkış Yap',
            style: GoogleFonts.inter(color: kTextPrimary)),
        content: Text('Hesabınızdan çıkmak istediğinize emin misiniz?',
            style: GoogleFonts.inter(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: GoogleFonts.inter(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(sessionProvider.notifier).logout();
            },
            child: Text('Çıkış Yap',
                style: GoogleFonts.inter(color: kRed)),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? kAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: active ? kAccent : kTextSecondary, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? kAccent : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
