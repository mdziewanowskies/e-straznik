import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../providers/supabase_provider.dart';
import '../theme/colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final orgAsync = ref.watch(organizationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Brak profilu.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: 'Profil',
                children: [
                  _Row(label: 'Email', value: profile.email),
                  if (profile.fullName != null)
                    _Row(label: 'Imię i nazwisko', value: profile.fullName!),
                  _Row(
                    label: 'Organizacja',
                    value: orgAsync.value?.name ?? '—',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Powiadomienia',
                children: [
                  _Row(
                    label: 'Push',
                    value: profile.pushEnabled ? 'Włączone' : 'Wyłączone',
                  ),
                  _Row(
                    label: 'Email',
                    value: profile.notificationPrefs['email'] == true
                        ? 'Włączone'
                        : 'Wyłączone',
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Preferencje powiadomień edytujesz w panelu webowym e-strażnika.',
                      style:
                          TextStyle(color: AppColors.mutedFg, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout, color: AppColors.danger),
                label: const Text('Wyloguj',
                    style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'e-Strażnik • wersja 1.0.0',
                  style: TextStyle(color: AppColors.mutedFg, fontSize: 11),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.mutedFg, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
