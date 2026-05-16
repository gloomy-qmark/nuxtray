import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vpn_provider.dart';



class DomainRoutingScreen extends StatefulWidget {
  const DomainRoutingScreen({super.key});

  @override
  State<DomainRoutingScreen> createState() => _DomainRoutingScreenState();
}

class _DomainRoutingScreenState extends State<DomainRoutingScreen> {
  // Domain input controller not needed at state level; created locally where required.

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final settings = vpn.settings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Маршрутизация доменов'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Проксировать'),
              Tab(text: 'Обход'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DomainList(
              domains: settings.proxyDomains,
              onAdd: (domain) => _addDomain(vpn, settings, domain, true),
              onRemove: (domain) => _removeDomain(vpn, settings, domain, true),
              title: 'Проксировать домены',
              subtitle: 'Эти домены всегда будут идти через VPN',
            ),
            _DomainList(
              domains: settings.directDomains,
              onAdd: (domain) => _addDomain(vpn, settings, domain, false),
              onRemove: (domain) => _removeDomain(vpn, settings, domain, false),
              title: 'Обход доменов',
              subtitle: 'Эти домены всегда будут идти напрямую',
            ),
          ],
        ),
      ),
    );
  }

  void _addDomain(VpnProvider vpn, VpnSettings settings, String domain, bool isProxy) {
    if (domain.isEmpty) return;
    final newList = List<String>.from(isProxy ? settings.proxyDomains : settings.directDomains);
    if (!newList.contains(domain)) {
      newList.add(domain);
      vpn.updateSettings(VpnSettings(
        socksPort: settings.socksPort,
        httpPort: settings.httpPort,
        bypassLan: settings.bypassLan,
        themeMode: settings.themeMode,
        language: settings.language,
        allowedApps: settings.allowedApps,
        excludedApps: settings.excludedApps,
        proxyDomains: isProxy ? newList : settings.proxyDomains,
        directDomains: isProxy ? settings.directDomains : newList,
        splitMode: settings.splitMode,
      ));
    }
  }

  void _removeDomain(VpnProvider vpn, VpnSettings settings, String domain, bool isProxy) {
    final newList = List<String>.from(isProxy ? settings.proxyDomains : settings.directDomains);
    newList.remove(domain);
    vpn.updateSettings(VpnSettings(
      socksPort: settings.socksPort,
      httpPort: settings.httpPort,
      bypassLan: settings.bypassLan,
      themeMode: settings.themeMode,
      language: settings.language,
      allowedApps: settings.allowedApps,
      excludedApps: settings.excludedApps,
      proxyDomains: isProxy ? newList : settings.proxyDomains,
      directDomains: isProxy ? settings.directDomains : newList,
      splitMode: settings.splitMode,
    ));
  }
}

class _DomainList extends StatelessWidget {
  final List<String> domains;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final String title;
  final String subtitle;

  const _DomainList({
    required this.domains,
    required this.onAdd,
    required this.onRemove,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              Text(subtitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'example.com или .google.com',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      onAdd(controller.text);
                      controller.clear();
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: domains.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(domains[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(domains[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
