import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nuxtray/vpn_provider.dart';
import 'package:provider/provider.dart';



class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  final Map<String, bool> _expandedGroups = {};

  void _confirmDeleteGroup(BuildContext context, VpnProvider vpn, String groupName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление группы'),
        content: Text('Вы уверены, что хотите удалить все сервера в группе "$groupName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              vpn.deleteGroup(groupName);
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vpn = Provider.of<VpnProvider>(context);
    final theme = Theme.of(context);

    // Group servers by their group property
    final groupedServers = <String, List<ServerInfo>>{};
    for (var server in vpn.servers) {
      groupedServers.putIfAbsent(server.group, () => []).add(server);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // SliverAppBar.medium(
            //   title: const Text('Список серверов'),
            //   pinned: true,
            // ),
            
            if (vpn.servers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dns_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withAlpha(100),
                      ),
                      const SizedBox(height: 24),
                      const Text('Список серверов пуст'),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final groupName = groupedServers.keys.elementAt(index);
                      final groupServers = groupedServers[groupName]!;
                      final isExpanded = _expandedGroups[groupName] ?? true;

                      return _ServerGroup(
                        name: groupName,
                        servers: groupServers,
                        isExpanded: isExpanded,
                        onToggle: () {
                          setState(() {
                            _expandedGroups[groupName] = !isExpanded;
                          });
                        },
                        onDelete: () => _confirmDeleteGroup(context, vpn, groupName),
                        selectedServer: vpn.selectedServer,
                        onServerTap: (server) {
                          HapticFeedback.lightImpact();
                          vpn.selectServer(server);
                        },
                      );
                    },
                    childCount: groupedServers.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _ServerGroup extends StatelessWidget {
  final String name;
  final List<ServerInfo> servers;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ServerInfo? selectedServer;
  final Function(ServerInfo) onServerTap;

  const _ServerGroup({
    required this.name,
    required this.servers,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.selectedServer,
    required this.onServerTap,
  });

  @override
  Widget build(BuildContext context) {
    final vpn = Provider.of<VpnProvider>(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isExpanded ? Icons.expand_more : Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          IconButton(
                            icon: const Icon(Icons.sync),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              vpn.syncGroup(name);
                            },
                            color: theme.colorScheme.onSurfaceVariant,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.speed),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              vpn.checkGroupPing(name);
                            },
                            color: theme.colorScheme.onSurfaceVariant,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: onDelete,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SizeTransition(sizeFactor: animation, child: child);
              },
              child: isExpanded
                  ? Column(
                      children: servers.map((server) {
                        final isSelected = selectedServer == server;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: _ServerDetailedCard(
                            server: server,
                            isSelected: isSelected,
                            onTap: () => onServerTap(server),
                          ),
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServerDetailedCard extends StatelessWidget {
  final ServerInfo server;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServerDetailedCard({
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withAlpha(100) 
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isSelected 
            ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      server.protocol,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (server.ping != 0)
                Text(
                  server.ping == -1 ? '—' : '${server.ping} ms',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.speed, size: 20, color: theme.colorScheme.onSurfaceVariant),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Provider.of<VpnProvider>(context, listen: false).checkServerPing(server);
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
