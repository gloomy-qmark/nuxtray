import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:provider/provider.dart';
import '../vpn_provider.dart';

class SplitTunnelingScreen extends StatefulWidget {
  const SplitTunnelingScreen({super.key});

  @override
  State<SplitTunnelingScreen> createState() => _SplitTunnelingScreenState();
}

class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {
  List<Application> _apps = [];
  final Map<String, bool> _selectedApps = {};
  String _mode = 'direct';
  bool _loading = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final vpn = Provider.of<VpnProvider>(context, listen: false);
    final settings = vpn.settings;
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
      );
      setState(() {
        _apps = apps;
        _mode = settings.splitMode;
        for (var app in _apps) {
          final pkg = app.packageName;
          if (_mode == 'direct') {
            _selectedApps[pkg] = settings.excludedApps.contains(pkg);
          } else {
            _selectedApps[pkg] = settings.allowedApps.contains(pkg);
          }
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _selectedCount => _selectedApps.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Tunneling'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'direct',
                  label: Text('Обход'),
                  icon: Icon(Icons.block_outlined),
                ),
                ButtonSegment(
                  value: 'route',
                  label: Text('Маршрут'),
                  icon: Icon(Icons.vpn_lock_outlined),
                ),
              ],
              selected: <String>{_mode},
              onSelectionChanged: (selection) {
                final val = selection.first;
                setState(() => _mode = val);
                vpn.updateSettings(vpn.settings.copyWith(splitMode: val));
              },
              multiSelectionEnabled: false,
              showSelectedIcon: false,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apps_outlined, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Приложения не найдены', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_selectedCount > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Выбрано: $_selectedCount',
                                style: TextStyle(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _apps.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final app = _apps[index];
                          final isSelected = _selectedApps[app.packageName] ?? false;
                          return Card(
                            elevation: 0,
                            color: isSelected ? cs.secondaryContainer.withValues(alpha: 0.4) : cs.surfaceContainerLow,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: isSelected
                                  ? BorderSide(color: cs.secondary.withValues(alpha: 0.5), width: 1)
                                  : BorderSide.none,
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                app.appName,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                app.packageName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedApps[app.packageName] = value ?? false;
                                });
                              },
                              secondary: app is ApplicationWithIcon
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(app.icon, width: 36, height: 36),
                                    )
                                  : Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.android, color: cs.onSurfaceVariant),
                                    ),
                              controlAffinity: ListTileControlAffinity.trailing,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              dense: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _searching ? null : () {
          setState(() => _searching = true);
          final selected = _selectedApps.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList();

          if (_mode == 'direct') {
            vpn.updateSettings(vpn.settings.copyWith(excludedApps: selected));
          } else {
            vpn.updateSettings(vpn.settings.copyWith(allowedApps: selected));
          }

          if (context.mounted) Navigator.pop(context);
        },
        icon: _searching
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          _mode == 'direct' ? 'Сохранить обход' : 'Сохранить маршрут',
        ),
      ),
    );
  }
}
