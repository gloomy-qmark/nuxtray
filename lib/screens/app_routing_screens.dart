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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Маршрутизация доменов'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Проксировать'),
              Tab(text: 'Обход'),
              Tab(text: 'Geo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DomainList(
              domains: settings.proxyDomains,
              onAdd: (domain) => _addDomain(vpn, settings, domain, true),
              onRemove: (domain) => _removeDomain(vpn, settings, domain, true),
              hint: 'example.com / geoip:ru / geosite:netflix / regexp:.*\\.ru',
              emptyIcon: Icons.shield_outlined,
              emptyText: 'Нет прокси-правил',
            ),
            _DomainList(
              domains: settings.directDomains,
              onAdd: (domain) => _addDomain(vpn, settings, domain, false),
              onRemove: (domain) => _removeDomain(vpn, settings, domain, false),
              hint: 'example.com / geoip:ru / geosite:google / regexp:.*\\.ru',
              emptyIcon: Icons.block_outlined,
              emptyText: 'Нет правил обхода',
            ),
            _GeoTab(settings: settings, vpn: vpn),
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
      vpn.updateSettings(settings.copyWith(
        proxyDomains: isProxy ? newList : settings.proxyDomains,
        directDomains: isProxy ? settings.directDomains : newList,
      ));
    }
  }

  void _removeDomain(VpnProvider vpn, VpnSettings settings, String domain, bool isProxy) {
    final newList = List<String>.from(isProxy ? settings.proxyDomains : settings.directDomains);
    newList.remove(domain);
    vpn.updateSettings(settings.copyWith(
      proxyDomains: isProxy ? newList : settings.proxyDomains,
      directDomains: isProxy ? settings.directDomains : newList,
    ));
  }
}

class _GeoTab extends StatelessWidget {
  final VpnSettings settings;
  final VpnProvider vpn;

  const _GeoTab({required this.settings, required this.vpn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Файлы GeoIP и GeoSite', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Укажите URL для скачивания geoip.dat и geosite.dat.\n'
          'Правила geoip:XX и geosite:XX в списках выше будут работать\n'
          'только при наличии этих файлов.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _GeoFileCard(
          title: 'geoip.dat',
          url: settings.geoipUrl,
          updatedAt: settings.geoipUpdatedAt,
          onUrlChanged: (val) => vpn.updateSettings(settings.copyWith(geoipUrl: val)),
          onUpdate: () async {
            if (settings.geoipUrl.isEmpty) return;
            final ok = await vpn.downloadGeoFile(settings.geoipUrl, 'geoip');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'geoip.dat обновлён' : 'Ошибка скачивания geoip.dat'),
              ));
            }
          },
        ),
        const SizedBox(height: 12),
        _GeoFileCard(
          title: 'geosite.dat',
          url: settings.geositeUrl,
          updatedAt: settings.geositeUpdatedAt,
          onUrlChanged: (val) => vpn.updateSettings(settings.copyWith(geositeUrl: val)),
          onUpdate: () async {
            if (settings.geositeUrl.isEmpty) return;
            final ok = await vpn.downloadGeoFile(settings.geositeUrl, 'geosite');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'geosite.dat обновлён' : 'Ошибка скачивания geosite.dat'),
              ));
            }
          },
        ),
      ],
    );
  }
}

class _GeoFileCard extends StatefulWidget {
  final String title;
  final String url;
  final int updatedAt;
  final ValueChanged<String> onUrlChanged;
  final VoidCallback onUpdate;

  const _GeoFileCard({
    required this.title,
    required this.url,
    required this.updatedAt,
    required this.onUrlChanged,
    required this.onUpdate,
  });

  @override
  State<_GeoFileCard> createState() => _GeoFileCardState();
}

class _GeoFileCardState extends State<_GeoFileCard> {
  late TextEditingController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
  }

  @override
  void didUpdateWidget(_GeoFileCard old) {
    super.didUpdateWidget(old);
    if (widget.url != old.url && widget.url != _controller.text) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(int ts) {
    if (ts <= 0) return 'не обновлялся';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                if (_loading)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                if (!_loading)
                  FilledButton.tonalIcon(
                    onPressed: widget.url.isEmpty ? null : () async {
                      setState(() => _loading = true);
                      widget.onUpdate();
                      setState(() => _loading = false);
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Обновить'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'https://github.com/.../geoip.dat',
                prefixIcon: const Icon(Icons.link, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.restore_outlined, size: 20),
                  onPressed: () {
                    _controller.clear();
                    widget.onUrlChanged('');
                  },
                  tooltip: 'Очистить',
                ),
              ),
              onChanged: widget.onUrlChanged,
            ),
            const SizedBox(height: 8),
            Text(
              'Последнее обновление: ${_formatDate(widget.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
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

  IconData _ruleIcon(String entry) {
    if (entry.startsWith('geoip:')) return Icons.public;
    if (entry.startsWith('geosite:')) return Icons.language;
    if (entry.startsWith('regexp:')) return Icons.code;
    if (entry.contains('/')) return Icons.alt_route;
    return Icons.language;
  }

  Color _ruleColor(String entry, ColorScheme cs) {
    if (entry.startsWith('geoip:')) return cs.tertiary;
    if (entry.startsWith('geosite:')) return cs.secondary;
    if (entry.startsWith('regexp:')) return cs.error;
    if (entry.contains('/')) return cs.primary;
    return cs.secondary;
  }

  String _ruleBadge(String entry) {
    if (entry.startsWith('geoip:')) return 'geoip';
    if (entry.startsWith('geosite:')) return 'geosite';
    if (entry.startsWith('regexp:')) return 'regex';
    if (entry.contains('/')) return 'cidr';
    return 'domain';
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
                    final entry = widget.domains[index];
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
                            color: _ruleColor(entry, cs).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_ruleIcon(entry), size: 18, color: _ruleColor(entry, cs)),
                        ),
                        title: Text(
                          entry,
                          style: TextStyle(
                            fontFamily: entry.startsWith('regexp:') ? 'monospace' : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _ruleBadge(entry),
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: cs.error.withValues(alpha: 0.7)),
                              onPressed: () => widget.onRemove(entry),
                              tooltip: 'Удалить',
                            ),
                          ],
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
