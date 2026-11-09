import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_lock_settings.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    final authenticated =
        await AppLockSettings.instance.authenticateWithBiometrics();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (authenticated) widget.onUnlocked();
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      setState(() => _error = 'Indique o seu PIN.');
      return;
    }
    final valid = await AppLockSettings.instance.verifyPin(pin);
    if (!mounted) return;
    if (valid) {
      widget.onUnlocked();
      return;
    }
    _pinController.clear();
    setState(() => _error = 'PIN incorreto. Tente novamente.');
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppLockSettings.instance;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Monni bloqueado',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Introduza o PIN para continuar.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _pinController,
                      autofocus: !settings.biometricsEnabled,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      onSubmitted: (_) => _unlockWithPin(),
                      decoration: InputDecoration(
                        labelText: 'PIN',
                        counterText: '',
                        errorText: _error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _unlockWithPin,
                      child: const Text('Desbloquear'),
                    ),
                    if (settings.biometricsEnabled &&
                        settings.biometricsAvailable) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _authenticating ? null : _authenticate,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Usar biometria'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
