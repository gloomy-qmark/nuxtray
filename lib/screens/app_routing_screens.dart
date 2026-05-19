import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vpn_provider.dart';

class DomainRoutingScreen extends StatefulWidget {
  const DomainRoutingScreen({super.key});

  @override
  State<DomainRoutingScreen> createState() => _DomainRoutingScreenState();
}

class _DomainRoutingScreenState extends State<DomainRoutingScreen> {
  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final settings = vpn.settings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Маршрутизация доменов'),
          bottom: TabBar(
            tabs: const [
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
              hint: 'example.com',
              emptyIcon: Icons.shield_outlined,
              emptyText: 'Нет прокси-доменов',
            ),
            _DomainList(
              domains: settings.directDomains,
              onAdd: (domain) => _addDomain(vpn, settings, domain, false),
              onRemove: (domain) => _removeDomain(vpn, settings, domain, false),
              hint: 'example.com',
              emptyIcon: Icons.block_outlined,
              emptyText: 'Нет доменов для обхода',
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
        adDisabled: settings.adDisabled,
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

class _DomainList extends StatefulWidget {
  final List<String> domains;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final String hint;
  final IconData emptyIcon;
  final String emptyText;

  const _DomainList({
    required this.domains,
    required this.onAdd,
    required this.onRemove,
    required this.hint,
    required this.emptyIcon,
    required this.emptyText,
  });

  @override
  State<_DomainList> createState() => _DomainListState();
}

class _DomainListState extends State<_DomainList> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onAdd(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    prefixIcon: const Icon(Icons.language, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _submit,
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.domains.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.emptyIcon, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(widget.emptyText, style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.domains.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.language, size: 18, color: cs.onSecondaryContainer),
                        ),
                        title: Text(widget.domains[index]),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: cs.error.withValues(alpha: 0.7)),
                          onPressed: () => widget.onRemove(widget.domains[index]),
                          tooltip: 'Удалить',
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
