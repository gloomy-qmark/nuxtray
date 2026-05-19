import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nuxtray/vpn_provider.dart';
import 'package:provider/provider.dart';

enum _GroupAction { sync, ping, delete }

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
          FilledButton(
            onPressed: () {
              vpn.deleteGroup(groupName);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vpn = Provider.of<VpnProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final groupedServers = <String, List<ServerInfo>>{};
    for (var server in vpn.servers) {
      groupedServers.putIfAbsent(server.group, () => []).add(server);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: const Text('Список серверов'),
              centerTitle: true,
              pinned: true,
            ),
            if (vpn.servers.isEmpty)
              SliverFillRemaining(
                hasScrollBody: true,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        Icon(
                          Icons.dns_outlined,
                          size: 64,
                          color: cs.primary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Список серверов пуст',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавьте подписку на главном экране',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
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

                      return _AnimatedServerGroup(
                        index: index,
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

class _AnimatedServerGroup extends StatefulWidget {
  final int index;
  final String name;
  final List<ServerInfo> servers;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ServerInfo? selectedServer;
  final Function(ServerInfo) onServerTap;

  const _AnimatedServerGroup({
    required this.index,
    required this.name,
    required this.servers,
    required this.isExpanded,
    required this.onToggle,
    required this.onDelete,
    required this.selectedServer,
    required this.onServerTap,
  });

  @override
  State<_AnimatedServerGroup> createState() => _AnimatedServerGroupState();
}

class _AnimatedServerGroupState extends State<_AnimatedServerGroup>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedServerGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpn = Provider.of<VpnProvider>(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (widget.index * 80).toInt()),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onToggle,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          widget.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (widget.isExpanded)
                        PopupMenuButton<_GroupAction>(
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: cs.onSurfaceVariant,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: cs.surfaceContainerHigh,
                          elevation: 2,
                          onSelected: (action) {
                            switch (action) {
                              case _GroupAction.sync:
                                HapticFeedback.mediumImpact();
                                vpn.syncGroup(widget.name);
                              case _GroupAction.ping:
                                HapticFeedback.mediumImpact();
                                vpn.checkGroupPing(widget.name);
                              case _GroupAction.delete:
                                widget.onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _GroupAction.sync,
                              child: Row(
                                children: [
                                  Icon(Icons.sync, size: 20, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 12),
                                  const Text('Синхронизировать'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: _GroupAction.ping,
                              child: Row(
                                children: [
                                  Icon(Icons.speed, size: 20, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 12),
                                  const Text('Проверить пинг'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: _GroupAction.delete,
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: cs.error),
                                  const SizedBox(width: 12),
                                  Text('Удалить', style: TextStyle(color: cs.error)),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                axisAlignment: -1.0,
                sizeFactor: _expandAnimation,
                child: Column(
                  children: List.generate(widget.servers.length, (i) {
                    final server = widget.servers[i];
                    final isSelected = widget.selectedServer == server;
                    return _StaggeredServerCard(
                      index: i,
                      server: server,
                      isSelected: isSelected,
                      onTap: () => widget.onServerTap(server),
                      expandAnimation: _expandAnimation,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StaggeredServerCard extends StatelessWidget {
  final int index;
  final ServerInfo server;
  final bool isSelected;
  final VoidCallback onTap;
  final Animation<double> expandAnimation;

  const _StaggeredServerCard({
    required this.index,
    required this.server,
    required this.isSelected,
    required this.onTap,
    required this.expandAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final staggerDelay = 0.025 * index;
    final staggerStart = (staggerDelay / 0.35).clamp(0.0, 0.85);
    final staggerEnd = ((staggerDelay + 0.10) / 0.35).clamp(0.1, 0.95);

    return AnimatedBuilder(
      animation: expandAnimation,
      builder: (context, child) {
        final progress = expandAnimation.value;
        final itemProgress = (progress - staggerStart) / (staggerEnd - staggerStart);
        final clamped = itemProgress.clamp(0.0, 1.0);
        final anim = Curves.easeOutCubic.transform(clamped);

        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - anim)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: isSelected
              ? cs.primaryContainer
              : cs.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSelected
                ? BorderSide(color: cs.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _ProtocolChip(protocol: server.protocol),
                            const SizedBox(width: 8),
                            if (server.ping != 0)
                              _PingBadge(ping: server.ping, isSelected: isSelected),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Consumer<VpnProvider>(
                    builder: (context, vpn, _) {
                      final isPinging = vpn.pingingServers
                          .contains('${server.config}::${server.name}');
                      if (isPinging) {
                        return const SizedBox(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        icon: Icon(
                          Icons.speed,
                          size: 20,
                          color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          vpn.checkServerPing(server);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Проверить пинг',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _ProtocolChip extends StatelessWidget {
  final String protocol;
  const _ProtocolChip({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        protocol,
        style: TextStyle(
          color: cs.onTertiaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PingBadge extends StatelessWidget {
  final int ping;
  final bool isSelected;
  const _PingBadge({required this.ping, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = ping == -1
        ? cs.error
        : ping < 100
            ? cs.primary
            : ping < 250
                ? cs.tertiary
                : cs.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ping == -1 ? '—' : '$ping ms',
        style: TextStyle(
          color: isSelected ? cs.onPrimaryContainer : color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
