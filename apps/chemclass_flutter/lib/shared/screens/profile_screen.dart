import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_config.dart';
import '../../core/theme.dart';
import '../../state/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final profile = authState.profile;
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? config.roleLabel,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 8),
                Text('Rol: ${config.roleLabel}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => authState.signOut(),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
