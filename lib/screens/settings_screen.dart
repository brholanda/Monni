import 'package:flutter/material.dart';

import '../data/accessibility_settings.dart';
import '../data/app_lock_settings.dart';
import '../theme/app_theme.dart';
import 'app_lock_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AccessibilitySettings.instance,
        AppLockSettings.instance,
      ]),
      builder: (context, _) {
        final settings = AccessibilitySettings.instance;
        final percentage = (settings.fontScale * 100).round();
        return Scaffold(
          appBar: AppBar(title: const Text('Configurações')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Leitura',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tamanho da fonte',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text('$percentage%'),
                              ],
                            ),
                            Slider(
                              value: settings.fontScale,
                              min: AccessibilitySettings.minFontScale,
                              max: AccessibilitySettings.maxFontScale,
                              divisions: 6,
                              label: '$percentage%',
                              onChanged: settings.setFontScale,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Menor',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Maior',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Exemplo de leitura confortável',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'O tamanho escolhido será usado em todo o aplicativo.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: settings.fontScale ==
                                      AccessibilitySettings.defaultFontScale
                                  ? null
                                  : () => settings.setFontScale(
                                        AccessibilitySettings.defaultFontScale,
                                      ),
                              child: const Text('Repor tamanho padrão'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Segurança',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Bloqueio da aplicação'),
                        subtitle: Text(
                          AppLockSettings.instance.hasPin
                              ? 'PIN ativado'
                              : 'Desativado',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AppLockSettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
