import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nuxtray/vpn_provider.dart';
import 'package:nuxtray/screens/settings_screen.dart';
import 'package:nuxtray/screens/page_transition.dart';
import 'package:nuxtray/screens/shrimp_ad.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vpn = Provider.of<VpnProvider>(context);
    _updatePulse(vpn.status);
  }

  void _updatePulse(VpnStatus status) {
    if (status == VpnStatus.connected) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showAddServerDialog(BuildContext context, VpnProvider vpn) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_link),
            SizedBox(width: 12),
            Text('Новая подписка'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Введите ссылку на подписку или конфигурацию:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'vless://... или https://...',
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.content_paste_go),
                    tooltip: 'Вставить из буфера',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        controller.text = data!.text!;
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final input = controller.text.trim();
              if (input.isNotEmpty) {
                final success = await vpn.addSubscription(input);
                if (success) {
                  if (context.mounted) Navigator.pop(context);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ошибка при добавлении подписки. Проверьте ссылку.')),
                    );
                  }
                }
              }
            },
            child: const Text('Добавить'),
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
    final isConnected = vpn.status == VpnStatus.connected;
    final hasServers = vpn.servers.isNotEmpty;
    final hasSelected = vpn.selectedServer != null;

    _updatePulse(vpn.status);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(context, smoothRoute(const SettingsScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddServerDialog(context, vpn),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _AnimatedConnectionCircle(
                  vpn: vpn,
                  pulseAnimation: _pulseAnimation,
                  glowAnimation: _glowAnimation,
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(0, 0.12),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOutCubic)),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: hasSelected
                      ? _buildServerInfo(context, vpn, cs, isConnected, theme)
                      : _buildEmptyState(context, cs, hasServers, theme, vpn.settings.adDisabled),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerInfo(
    BuildContext context,
    VpnProvider vpn,
    ColorScheme cs,
    bool isConnected,
    ThemeData theme,
  ) {
    return Column(
      key: const ValueKey('server_info'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          // decoration: BoxDecoration(
          //   color: cs.tertiaryContainer.withValues(alpha: 0.6),
          //   borderRadius: BorderRadius.circular(24),
          // ),
          child: Text(
            vpn.selectedServer!.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onTertiaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(opacity: value, child: child);
          },
          child: Card(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.7),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AnimatedStatItem(
                    icon: Icons.arrow_downward_rounded,
                    value: vpn.downSpeed,
                    label: 'ВХОД',
                    color: isConnected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  _AnimatedStatItem(
                    icon: Icons.arrow_upward_rounded,
                    value: vpn.upSpeed,
                    label: 'ИСХОД',
                    color: isConnected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  Container(
                    height: 32,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  _AnimatedStatItem(
                    icon: Icons.speed_rounded,
                    value: vpn.selectedServer!.ping == 0
                        ? '—'
                        : '${vpn.selectedServer!.ping} ms',
                    label: 'ПИНГ',
                    color: isConnected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme cs, bool hasServers, ThemeData theme, bool adDisabled) {
    return Column(
      key: const ValueKey('empty_state'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasServers ? Icons.touch_app_rounded : Icons.dns_outlined,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                hasServers ? 'Выберите сервер' : 'Нет подписок',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!hasServers && !adDisabled) ...[
          const SizedBox(height: 24),
          const ShrimpAd(),
        ],
      ],
    );
  }
}

class _AnimatedConnectionCircle extends StatelessWidget {
  final VpnProvider vpn;
  final Animation<double> pulseAnimation;
  final Animation<double> glowAnimation;

  const _AnimatedConnectionCircle({
    required this.vpn,
    required this.pulseAnimation,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isConnected = vpn.status == VpnStatus.connected;
    final isConnecting = vpn.status == VpnStatus.connecting;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        vpn.toggleConnection();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseAnimation, glowAnimation]),
        builder: (context, child) {
          final pulse = isConnecting
              ? 0.97
              : isConnected
                  ? pulseAnimation.value
                  : 1.0;
          final glow = isConnected ? glowAnimation.value * 0.4 : 0.0;
          return Transform.scale(
            scale: pulse,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? cs.primary : cs.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: glow),
                    blurRadius: 30 + glow * 20,
                    spreadRadius: glow * 8,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation.drive(
                        Tween<double>(begin: 0.85, end: 1.0)
                            .chain(CurveTween(curve: Curves.easeOutBack)),
                      ),
                      child: child,
                    ),
                  );
                },
                child: isConnecting
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Column(
                        key: ValueKey(isConnected),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.power_settings_new_rounded,
                            size: 48,
                            color: isConnected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          if (isConnected) ...[
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(vpn.connectionDuration),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _AnimatedStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _AnimatedStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, _, child) {
              return AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: color,
                ),
                child: Text(value),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
