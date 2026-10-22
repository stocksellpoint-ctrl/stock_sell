import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_size.dart';
import '../providers/settings_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          _sectionTitle('Theme'),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            title: const Text('Light'),
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            title: const Text('Dark'),
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            title: const Text('System'),
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          const SizedBox(height: AppSizes.lg),

          _sectionTitle('Accent color'),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: SettingsProvider.presetColors.map((c) {
              final selected = c.value == settings.seedColor.value;
              return GestureDetector(
                onTap: () => settings.setSeedColor(c),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.xl),

         
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );
}