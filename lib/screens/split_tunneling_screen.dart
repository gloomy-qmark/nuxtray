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
  Map<String, bool> _selectedApps = {};
  String _mode = 'direct'; // 'direct' or 'route'

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final vpn = Provider.of<VpnProvider>(context, listen: false);
    final settings = vpn.settings;
    final apps = await DeviceApps.getInstalledApplications(includeAppIcons: true, includeSystemApps: false);

    setState(() {
      _apps = apps;
      // initialize mode from settings
      _mode = settings.splitMode;
      // Initialize selected apps based on saved settings
      for (var app in _apps) {
        final pkg = app.packageName;
        if (_mode == 'direct') {
          _selectedApps[pkg] = settings.excludedApps.contains(pkg);
        } else {
          _selectedApps[pkg] = settings.allowedApps.contains(pkg);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Tunneling'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'direct', label: Text('Direct')),
                      ButtonSegment(value: 'route', label: Text('Route')),
                    ],
                    selected: <String>{_mode},
                    onSelectionChanged: (selection) {
                      final val = selection.first;
                      setState(() {
                        _mode = val;
                      });
                      final vpn = Provider.of<VpnProvider>(context, listen: false);
                      final s = vpn.settings;
                      vpn.updateSettings(VpnSettings(
                        socksPort: s.socksPort,
                        httpPort: s.httpPort,
                        bypassLan: s.bypassLan,
                        themeMode: s.themeMode,
                        language: s.language,
                        allowedApps: s.allowedApps,
                        excludedApps: s.excludedApps,
                        proxyDomains: s.proxyDomains,
                        directDomains: s.directDomains,
                        splitMode: _mode,
                      ));
                    },
                    multiSelectionEnabled: false,
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _apps.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, index) {
                Application app = _apps[index];
                return CheckboxListTile(
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                  value: _selectedApps[app.packageName] ?? false,
                  onChanged: (bool? value) {
                    setState(() {
                      _selectedApps[app.packageName] = value ?? false;
                    });
                  },
                  secondary: app is ApplicationWithIcon
                      ? Image.memory(app.icon)
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final vpn = Provider.of<VpnProvider>(context, listen: false);
          final s = vpn.settings;
          final selected = _selectedApps.entries.where((e) => e.value).map((e) => e.key).toList();

          if (_mode == 'direct') {
            vpn.updateSettings(VpnSettings(
              socksPort: s.socksPort,
              httpPort: s.httpPort,
              bypassLan: s.bypassLan,
              themeMode: s.themeMode,
              language: s.language,
              allowedApps: s.allowedApps,
              excludedApps: selected,
              proxyDomains: s.proxyDomains,
              directDomains: s.directDomains,
              splitMode: s.splitMode,
            ));
          } else {
            vpn.updateSettings(VpnSettings(
              socksPort: s.socksPort,
              httpPort: s.httpPort,
              bypassLan: s.bypassLan,
              themeMode: s.themeMode,
              language: s.language,
              allowedApps: selected,
              excludedApps: s.excludedApps,
              proxyDomains: s.proxyDomains,
              directDomains: s.directDomains,
              splitMode: s.splitMode,
            ));
          }

          if (context.mounted) Navigator.pop(context);
        },
        label: Text(_mode == 'direct' ? 'Режим: Обход' : 'Режим: Route'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
