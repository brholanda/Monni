import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_lock_settings.dart';
import '../theme/app_theme.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _createPin() async {
    final pin = _pinController.text;
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'O PIN deve ter entre 4 e 6 dígitos.');
      return;
    }
    if (pin != _confirmationController.text) {
      setState(() => _error = 'Os PINs não coincidem.');
      return;
    }

    setState(() => _saving = true);
    await AppLockSettings.instance.setPin(pin);
    if (!mounted) return;
    _pinController.clear();
    _confirmationController.clear();
    setState(() {
      _saving = false;
      _error = null;
    });
  }

  Future<void> _disable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desativar bloqueio?'),
        content: const Text(
          'O Monni deixará de pedir PIN ou biometria ao ser aberto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppLockSettings.instance.disable();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppLockSettings.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Bloqueio da aplicação')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!settings.hasPin) ...[
                    Text(
                      'Criar PIN',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Use um PIN de 4 a 6 dígitos para proteger o acesso aos seus dados.',
                            ),
                            const SizedBox(height: 16),
                            _PinField(
                              controller: _pinController,
                              label: 'Novo PIN',
                              autofocus: true,
                            ),
                            const SizedBox(height: 12),
                            _PinField(
                              controller: _confirmationController,
                              label: 'Confirmar PIN',
                              errorText: _error,
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _saving ? null : _createPin,
                              child: const Text('Ativar bloqueio'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Proteção ativa',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        children: [
                          const ListTile(
                            leading: Icon(Icons.pin_rounded),
                            title: Text('PIN ativado'),
                            subtitle: Text('Solicitado ao abrir o aplicativo.'),
                          ),
                          const Divider(height: 1),
                          SwitchListTile.adaptive(
                            secondary: const Icon(Icons.fingerprint_rounded),
                            title: const Text('Usar biometria'),
                            subtitle: Text(
                              settings.biometricsAvailable
                                  ? 'Use impressão digital ou reconhecimento facial.'
                                  : 'Biometria não disponível neste dispositivo.',
                            ),
                            value: settings.biometricsEnabled,
                            onChanged: settings.biometricsAvailable
                                ? settings.setBiometricsEnabled
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _disable,
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Desativar bloqueio'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    this.autofocus = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        errorText: errorText,
      ),
    );
  }
}
