import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vpn_provider.dart';
import 'app_routing_screens.dart';
import 'split_tunneling_screen.dart';
import 'page_transition.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnProvider>();
    final s = vpn.settings;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: 'Подключение'),
          _SettingTile(
            icon: Icons.lan_outlined,
            title: 'Обход локальной сети',
            subtitle: 'Не направлять трафик локальной сети через VPN',
            trailing: Switch(
              value: s.bypassLan,
              onChanged: (val) => vpn.updateSettings(s.copyWith(bypassLan: val)),
            ),
          ),
          _SettingTile(
            icon: Icons.wifi_tethering,
            title: 'Аварийное отключение',
            subtitle: 'Блокировать весь трафик при обрыве VPN',
            trailing: Switch(
              value: s.killSwitch,
              onChanged: (val) => vpn.updateSettings(s.copyWith(killSwitch: val)),
            ),
          ),
          _SettingTile(
            icon: Icons.numbers,
            title: 'SOCKS Порт',
            subtitle: s.socksPort.toString(),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => _showPortDialog(context, 'SOCKS Port', s.socksPort, (val) {
              vpn.updateSettings(s.copyWith(socksPort: val));
            }),
          ),
          _SettingTile(
            icon: Icons.http,
            title: 'HTTP Порт',
            subtitle: s.httpPort.toString(),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => _showPortDialog(context, 'HTTP Port', s.httpPort, (val) {
              vpn.updateSettings(s.copyWith(httpPort: val));
            }),
          ),
          _SettingTile(
            icon: Icons.apps,
            title: 'Проксирование приложений',
            subtitle: 'Выбрать приложения для работы через VPN',
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => Navigator.push(context, smoothRoute(const SplitTunnelingScreen())),
          ),
          _SettingTile(
            icon: Icons.domain,
            title: 'Маршрутизация доменов',
            subtitle: 'Настройка обхода или проксирования доменов',
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => Navigator.push(context, smoothRoute(const DomainRoutingScreen())),
          ),
          const _DividerWithPadding(),
          _SectionHeader(title: 'Приложение'),
          _SettingTile(
            icon: Icons.palette_outlined,
            title: 'Тема оформления',
            subtitle: _getThemeName(s.themeMode),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => _showThemeDialog(context, vpn),
          ),
          _SettingTile(
            icon: Icons.language,
            title: 'Язык',
            subtitle: s.language.toUpperCase(),
            trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            onTap: () => _showLanguageDialog(context, vpn),
          ),
          _SettingTile(
            icon: Icons.campaign_outlined,
            title: 'Отключить рекламу',
            subtitle: 'Показывать рекламу. Пожалуйста, не нажимайте данную галочку :(',
            trailing: Switch(
              value: s.adDisabled,
              onChanged: (val) => vpn.updateSettings(s.copyWith(adDisabled: val)),
            ),
          ),
          _SettingTile(
            icon: Icons.play_circle_outline,
            title: 'Автозапуск',
            subtitle: 'Подключаться к VPN при запуске приложения',
            trailing: Switch(
              value: s.autoStart,
              onChanged: (val) => vpn.updateSettings(s.copyWith(autoStart: val)),
            ),
          ),
          const _DividerWithPadding(),
          _SectionHeader(title: 'Экспериментальное'),
          _SettingTile(
            icon: Icons.track_changes,
            title: 'Обсерватория',
            subtitle: s.observatoryEnabled
                ? 'Активна · ${s.observatoryGroup} · каждые ${s.observatoryInterval}с'
                : 'Автоматический выбор лучшего сервера',
            trailing: Switch(
              value: s.observatoryEnabled,
              onChanged: (val) => vpn.updateSettings(s.copyWith(observatoryEnabled: val)),
            ),
          ),
          if (s.observatoryEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Группа для мониторинга',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey('obs_group_${s.observatoryGroup}'),
                        initialValue: s.observatoryGroup.isNotEmpty &&
                                vpn.observatoryGroupNames.contains(s.observatoryGroup)
                            ? s.observatoryGroup
                            : null,
                        items: vpn.observatoryGroupNames.map((g) =>
                            DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            vpn.updateSettings(s.copyWith(observatoryGroup: val));
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Интервал: ${s.observatoryInterval}с',
                                    style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(height: 4),
                                Text('Проверка пинга каждые ${s.observatoryInterval} секунд',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    )),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: Slider(
                              value: s.observatoryInterval.toDouble(),
                              min: 10,
                              max: 600,
                              divisions: 59,
                              label: '${s.observatoryInterval}с',
                              onChanged: (val) => vpn.updateSettings(
                                s.copyWith(observatoryInterval: val.round()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Автопереключение'),
                        subtitle: const Text('Автоматически переключаться на сервер с лучшим пингом'),
                        value: s.observatoryAutoSwitch,
                        onChanged: (val) => vpn.updateSettings(
                          s.copyWith(observatoryAutoSwitch: val ?? true),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getThemeName(String mode) {
    switch (mode) {
      case 'light': return 'Светлая';
      case 'dark': return 'Темная';
      default: return 'Системная';
    }
  }

  void _showPortDialog(BuildContext context, String title, int currentVal, Function(int) onSave) {
    final controller = TextEditingController(text: currentVal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Порт (1024-65535)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () {
            final val = int.tryParse(controller.text);
            if (val != null && val > 1024 && val < 65535) {
              onSave(val);
              Navigator.pop(context);
            }
          }, child: const Text('Сохранить')),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, VpnProvider vpn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите тему'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(mode: 'system', label: 'Системная', icon: Icons.settings_suggest_outlined, vpn: vpn),
            _ThemeOption(mode: 'light', label: 'Светлая', icon: Icons.light_mode_outlined, vpn: vpn),
            _ThemeOption(mode: 'dark', label: 'Темная', icon: Icons.dark_mode_outlined, vpn: vpn),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, VpnProvider vpn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangOption(code: 'ru', label: 'Русский', icon: Icons.language, vpn: vpn),
            _LangOption(code: 'en', label: 'English', icon: Icons.language, vpn: vpn),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerWithPadding extends StatelessWidget {
  const _DividerWithPadding();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: cs.onSecondaryContainer, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String mode;
  final String label;
  final IconData icon;
  final VpnProvider vpn;
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.vpn,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = vpn.settings.themeMode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          vpn.updateSettings(vpn.settings.copyWith(themeMode: mode));
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? cs.secondaryContainer.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final IconData icon;
  final VpnProvider vpn;
  const _LangOption({
    required this.code,
    required this.label,
    required this.icon,
    required this.vpn,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = vpn.settings.language == code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          vpn.updateSettings(vpn.settings.copyWith(language: code));
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? cs.secondaryContainer.withValues(alpha: 0.5) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isSelected ? cs.onSecondaryContainer : cs.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? cs.onSecondaryContainer : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: cs.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
