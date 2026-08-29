import 'package:flutter/material.dart';
import 'package:ecalculator/components/more_menu.dart';
import 'package:ecalculator/components/theme_provider.dart';
import 'package:ecalculator/components/logout_dialog.dart';
import 'package:ecalculator/other/app_theme_colors.dart';
import 'package:ecalculator/storage/settings_storage.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.logout});

  final Future<void> Function()? logout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settings = SettingsStorage();
  int _theme = 0;
  int _period = 0;
  bool _withPlusMinus = false;
  bool _isLoading = true;

  Future<void> _load() async {
    final values = await Future.wait<Object?>([
      _settings.readInt('theme'),
      _settings.readInt('period_type'),
      _settings.readBool('mark_type'),
    ]);
    if (!mounted) return;
    setState(() {
      _theme = values[0] as int? ?? 0;
      _period = values[1] as int? ?? 0;
      _withPlusMinus = values[2] as bool? ?? false;
      _isLoading = false;
    });
  }

  Future<void> _selectTheme(int value) async {
    setState(() => _theme = value);
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
    await _settings.writeInt('theme', value);
  }

  Future<void> _selectPeriod(int value) async {
    setState(() => _period = value);
    await _settings.writeInt('period_type', value);
  }

  Future<void> _setPlusMinus(bool value) async {
    setState(() => _withPlusMinus = value);
    await _settings.writeBool('mark_type', value);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        actions: const [MoreMenu(canLeave: false)],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppThemeColors.scaffoldText(context),
              ),
            )
          : ListView(
              key: const ValueKey('settings-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const _SectionTitle('Оформление'),
                _Surface(
                  child: SegmentedButton<int>(
                    key: const ValueKey('theme-selector'),
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    style: _segmentedStyle(scheme),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Стандартная')),
                      ButtonSegment(value: 1, label: Text('Светлая')),
                      ButtonSegment(value: 2, label: Text('Тёмная')),
                    ],
                    selected: {_theme},
                    onSelectionChanged: (values) => _selectTheme(values.first),
                  ),
                ),
                const _SectionTitle('Учебный период'),
                _Surface(
                  child: SegmentedButton<int>(
                    key: const ValueKey('period-type-selector'),
                    showSelectedIcon: false,
                    expandedInsets: EdgeInsets.zero,
                    style: _segmentedStyle(scheme),
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Четверти')),
                      ButtonSegment(value: 1, label: Text('Полугодия')),
                      ButtonSegment(value: 2, label: Text('Семестры')),
                    ],
                    selected: {_period},
                    onSelectionChanged: (values) => _selectPeriod(values.first),
                  ),
                ),
                const _SectionTitle('Калькулятор'),
                _Surface(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const ValueKey('plus-minus-setting'),
                    value: _withPlusMinus,
                    onChanged: _setPlusMinus,
                    title: const Text('Оценки + и −'),
                    subtitle: const Text('Например, 4+ и 5−'),
                    secondary: const Icon(Icons.exposure_outlined),
                  ),
                ),
                const _SectionTitle('Аккаунт'),
                _Surface(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    key: const ValueKey('settings-logout'),
                    onTap: () => showLogoutDialog(
                      context,
                      logout: widget.logout,
                    ),
                    leading: Icon(Icons.logout, color: scheme.error),
                    title: Text('Выйти', style: TextStyle(color: scheme.error)),
                  ),
                ),
              ],
            ),
    );
  }

  ButtonStyle _segmentedStyle(ColorScheme scheme) {
    return ButtonStyle(
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      ),
      textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13)),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurface,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainer,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppThemeColors.scaffoldText(context),
                fontWeight: FontWeight.w700,
              ),
        ),
      );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.padding = const EdgeInsets.all(8)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      );
}
