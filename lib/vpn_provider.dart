import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray_plus/flutter_v2ray.dart';
import 'package:path_provider/path_provider.dart';

enum VpnStatus { disconnected, connecting, connected }

class VpnSettings {
  int socksPort;
  int httpPort;
  bool bypassLan;
  String themeMode; // 'system', 'light', 'dark'
  String language; // 'ru', 'en'
  List<String> allowedApps;
  List<String> excludedApps;
  List<String> proxyDomains;
  List<String> directDomains;
  String splitMode; // 'direct' (selected apps bypass VPN) or 'route' (selected apps go through VPN)
  bool adDisabled;

  VpnSettings({
    this.socksPort = 10808,
    this.httpPort = 10809,
    this.bypassLan = true,
    this.themeMode = 'system',
    this.language = 'ru',
    this.allowedApps = const [],
    this.excludedApps = const [],
    this.proxyDomains = const [],
    this.directDomains = const [],
    this.splitMode = 'direct',
    this.adDisabled = false,
  });

  Map<String, dynamic> toJson() => {
    'socksPort': socksPort,
    'httpPort': httpPort,
    'bypassLan': bypassLan,
    'themeMode': themeMode,
    'language': language,
    'allowedApps': allowedApps,
    'excludedApps': excludedApps,
    'proxyDomains': proxyDomains,
    'directDomains': directDomains,
    'splitMode': splitMode,
    'adDisabled': adDisabled,
  };

  factory VpnSettings.fromJson(Map<String, dynamic> json) => VpnSettings(
    socksPort: json['socksPort'] ?? 10808,
    httpPort: json['httpPort'] ?? 10809,
    bypassLan: json['bypassLan'] ?? true,
    themeMode: json['themeMode'] ?? 'system',
    language: json['language'] ?? 'ru',
    allowedApps: List<String>.from(json['allowedApps'] ?? []),
    excludedApps: List<String>.from(json['excludedApps'] ?? []),
    proxyDomains: List<String>.from(json['proxyDomains'] ?? []),
    directDomains: List<String>.from(json['directDomains'] ?? []),
    splitMode: json['splitMode'] ?? 'direct',
    adDisabled: json['adDisabled'] ?? false,
  );
}

const Map<String, String> kFlagsMap = {
  "Finland": "🇫🇮",
  "Germany": "🇩🇪",
  "Turkey": "🇹🇷",
  "USA": "🇺🇸",
  "Canada": "🇨🇦",
  "Japan": "🇯🇵",
  "Singapore": "🇸🇬",
  "United Kingdom": "🇬🇧",
  "Europe": "🇪🇺",
  "France": "🇫🇷",
  "Netherlands": "🇳🇱",
  "Switzerland": "🇨🇭",
  "Spain": "🇪🇸",
  "Italy": "🇮🇹",
  "Portugal": "🇵🇹",
  "Ukraine": "🇺🇦",
  "Russia": "🇷🇺",
  "Kazakhstan": "🇰🇿",
  "Brazil": "🇧🇷",
  "Argentina": "🇦🇷",
  "India": "🇮🇳",
  "China": "🇨🇳",
  "South Korea": "🇰🇷",
  "Australia": "🇦🇺",
  "New Zealand": "🇳🇿",
  "Mexico": "🇲🇽",
  "Colombia": "🇨🇴",
  "Peru": "🇵🇪",
  "Chile": "🇨🇱",
  "Venezuela": "🇻🇪",
  "Egypt": "🇪🇬",
  "South Africa": "🇿🇦",
  "Nigeria": "🇳🇬",
  "Kenya": "🇰🇪",
  "Morocco": "🇲🇦",
  "Thailand": "🇹🇭",
  "Vietnam": "🇻🇳",
  "Indonesia": "🇮🇩",
  "Malaysia": "🇲🇾",
  "Philippines": "🇵🇭",
  "Pakistan": "🇵🇰",
  "Bangladesh": "🇧🇩",
  "Saudi Arabia": "🇸🇦",
  "UAE": "🇦🇪",
  "Qatar": "🇶🇦",
  "Kuwait": "🇰🇼",
  "Oman": "🇴🇲",
  "Bahrain": "🇧🇭",
  "Israel": "🇮🇱",
  "Austria": "🇦🇹",
  "Belgium": "🇧🇪",
  "Norway": "🇳🇴",
  "Sweden": "🇸🇪",
  "Denmark": "🇩🇰",
  "Ireland": "🇮🇪",
  "Poland": "🇵🇱",
  "Hungary": "🇭🇺",
  "Czech Republic": "🇨🇿",
  "Greece": "🇬🇷",
  "Romania": "🇷🇴",
  "Bulgaria": "🇧🇬",
  "Croatia": "🇭🇷",
  "Slovakia": "🇸🇰",
  "Slovenia": "🇸🇮",
  "Lithuania": "🇱🇹",
  "Latvia": "🇱🇻",
  "Estonia": "🇪🇪",
  "Belarus": "🇧🇾",
  "Azerbaijan": "🇦🇿",
  "Georgia": "🇬🇪",
  "Armenia": "🇦🇲",
  "Uzbekistan": "🇺🇿",
  "Kyrgyzstan": "🇰🇬",
  "Tajikistan": "🇹🇯",
  "Turkmenistan": "🇹🇲",
  "Mongolia": "🇲🇳",
  "Myanmar": "🇲🇲",
  "Cambodia": "🇰🇭",
  "Laos": "🇱🇦",
  "Nepal": "🇳🇵",
  "Sri Lanka": "🇱🇰",
  "Maldives": "🇲🇻",
  "Fiji": "🇫🇯",
  "Papua New Guinea": "🇵🇬",
  "Solomon Islands": "🇸🇧",
  "Vanuatu": "🇻🇺",
  "Samoa": "🇼🇸",
  "Tonga": "🇹🇴",
  "Kiribati": "🇰🇮",
  "Micronesia": "🇫🇲",
  "Palau": "🇵🇼",
  "Marshall Islands": "🇲🇭",
  "Nauru": "🇳🇷",
  "Tuvalu": "🇹🇻",
  "Cuba": "🇨🇺",
  "Dominican Republic": "🇩🇴",
  "Haiti": "🇭🇹",
  "Jamaica": "🇮🇲",
  "Trinidad and Tobago": "🇹🇹",
  "Barbados": "🇧🇧",
  "Guyana": "🇬🇾",
  "Suriname": "🇸🇷",
  "Paraguay": "🇵🇾",
  "Bolivia": "🇧🇴",
  "Ecuador": "🇪🇨",
  "Uruguay": "🇺🇾",
  "Panama": "🇵🇦",
  "Costa Rica": "🇨🇷",
  "Nicaragua": "🇳🇮",
  "Honduras": "🇭🇳",
  "El Salvador": "🇸🇻",
  "Guatemala": "🇬🇹",
  "Belize": "🇧🇿",
  "Syria": "🇸🇾",
  "Lebanon": "🇱🇧",
  "Jordan": "🇮🇴",
  "Iraq": "🇮🇶",
  "Iran": "🇮🇷",
  "Yemen": "🇾🇪",
  "Sudan": "🇸🇩",
  "Libya": "🇱🇾",
  "Tunisia": "🇹🇳",
  "Algeria": "🇩🇿",
  "Senegal": "🇸🇳",
  "Ivory Coast": "🇨🇮",
  "Ghana": "🇬🇭",
  "Ethiopia": "🇪🇹",
  "Rwanda": "🇷🇼",
  "Uganda": "🇺🇬",
  "Tanzania": "🇹🇿",
  "Zambia": "🇿🇲",
  "Zimbabwe": "🇿🇼",
  "Botswana": "🇧🇼",
  "Namibia": "🇳🇦",
  "Madagascar": "🇲🇬",
  "Mauritius": "🇲🇺",
  "Seychelles": "🇸🇨",
  "Malta": "🇲🇹",
  "Luxembourg": "🇱🇺",
  "Cyprus": "🇨🇾",
  "Iceland": "🇮🇸",
  "Andorra": "🇦🇩",
  "Monaco": "🇲🇨",
  "San Marino": "🇸🇲",
  "Vatican City": "🇻🇦",
  "Liechtenstein": "🇱🇮",
};

class ServerInfo {
  final String name;
  final String country;
  final String protocol;
  final int ping;
  final String group;
  final String config;

  ServerInfo({
    required this.name,
    this.country = '🌐',
    required this.protocol,
    required this.ping,
    this.group = 'General',
    required this.config,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'protocol': protocol,
    'ping': ping,
    'group': group,
    'config': config,
  };

  factory ServerInfo.fromJson(Map<String, dynamic> json) => ServerInfo(
    name: json['name'],
    country: json['country'] ?? '🌐',
    protocol: json['protocol'],
    ping: json['ping'],
    group: json['group'] ?? 'General',
    config: json['config'] ?? '',
  );
}

class VpnProvider extends ChangeNotifier {
  VpnStatus _status = VpnStatus.disconnected;
  ServerInfo? _selectedServer;
  String _hwid = "GENERATING...";
  String get hwid => _hwid;

  Timer? _connectionTimer;
  Duration _duration = Duration.zero;
  Duration get connectionDuration => _duration;

  String _deviceModel = "Unknown";
  String _osVersion = "Unknown";
  String _locale = "en-US";

  final List<ServerInfo> _servers = [
    // ServerInfo(
    //   name: 'Европа ⭐️ [авто-выбор]',
    //   country: 'Europe',
    //   protocol: 'VLESS',
    //   ping: 32,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Финляндия [быстрая]',
    //   country: 'Finland',
    //   protocol: 'Hysteria2',
    //   ping: 28,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Нидерланды [быстрая]',
    //   country: 'Netherlands',
    //   protocol: 'VLESS',
    //   ping: 42,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Россия [без блок.]',
    //   country: 'Russia',
    //   protocol: 'VLESS',
    //   ping: 15,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Германия',
    //   country: 'Germany',
    //   protocol: 'VLESS',
    //   ping: 48,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'США',
    //   country: 'USA',
    //   protocol: 'VLESS',
    //   ping: 120,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Япония',
    //   country: 'Japan',
    //   protocol: 'VLESS',
    //   ping: 210,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Аргентина',
    //   country: 'Argentina',
    //   protocol: 'VLESS',
    //   ping: 245,
    //   group: '🍤 I.Shrimp'
    // ),
    // ServerInfo(
    //   name: 'Турция',
    //   country: 'Turkey',
    //   protocol: 'VLESS',
    //   ping: 65,
    //   group: '🍤 I.Shrimp'
    // ),
  ];

  List<ServerInfo> get servers => _servers;

  void addServer(ServerInfo server) {
    _servers.add(server);
    if (_selectedServer == null) {
      _selectedServer = server;
    }
    _saveServers();
    notifyListeners();
  }

  void deleteGroup(String groupName) {
    _servers.removeWhere((s) => s.group == groupName);
    if (_selectedServer?.group == groupName) {
      _selectedServer = _servers.isNotEmpty ? _servers.first : null;
    }
    _saveServers();
    notifyListeners();
  }

  VpnSettings _settings = VpnSettings();
  VpnSettings get settings => _settings;

  void updateSettings(VpnSettings newSettings) {
    _settings = newSettings;
    _saveServers(); // We save settings in the same file or separate
    notifyListeners();
  }

  final flutterV2ray = FlutterV2ray();
  bool _v2rayInitialized = false;
  bool get isV2rayInitialized => _v2rayInitialized;
  String _upSpeed = "0 B/s";
  String _downSpeed = "0 B/s";
  String get upSpeed => _upSpeed;
  String get downSpeed => _downSpeed;

  void _initV2ray() async {
    try {
      await flutterV2ray.initializeVless(
        notificationIconResourceType: "mipmap",
        notificationIconResourceName: "ic_launcher",
      );
      _v2rayInitialized = true;
      notifyListeners();

      flutterV2ray.onStatusChanged.listen((status) {
        debugPrint('V2Ray Status: ${status.state}');
        _upSpeed = _formatSpeed(status.uploadSpeed);
        _downSpeed = _formatSpeed(status.downloadSpeed);

        if (status.state == 'CONNECTED') {
          if (_status != VpnStatus.connected) {
            _status = VpnStatus.connected;
            _startTimer();
          }
        } else if (status.state == 'CONNECTING') {
          _status = VpnStatus.connecting;
        } else {
          if (_status != VpnStatus.disconnected) {
            _status = VpnStatus.disconnected;
            _stopTimer();
            _upSpeed = "0 B/s";
            _downSpeed = "0 B/s";
          }
        }
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing V2Ray: $e');
    }
  }

  Future<bool> addSubscription(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    try {
      if (trimmed.startsWith('http')) {
        final uri = Uri.parse(trimmed);
        final groupName = uri.host;

        // Fetch from URL with custom headers
        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'X-App-Version': '1.0.0',
            'X-Device-Locale': _locale,
            'X-Device-Os': Platform.operatingSystem,
            'X-Device-Model': _deviceModel,
            'X-Hwid': _hwid,
            'X-Ver-Os': _osVersion,
            'Connection': 'Keep-Alive',
            'Accept-Encoding': 'gzip, deflate',
            'Accept-Language': 'ru-RU,en,*',
          },
        );

        if (response.statusCode == 200) {
          _groupSources[groupName] = trimmed; // Store the source URL
          final body = response.body.trim();
          try {
            final data = json.decode(body);

            debugPrint(data.toString());
            
            if (data is List) {
              for (var item in data) {
                _parseAndAddServer(item.toString(), groupName);
              }
            } else {
              _parseAndAddServer(data.toString(), groupName);
            }
          } catch (e) {
            try {
              String decoded = utf8.decode(base64.decode(body));
              final lines = decoded.split(RegExp(r'[\n\r]+'));
              for (var line in lines) {
                if (line.trim().isNotEmpty) {
                  _parseAndAddServer(line.trim(), groupName);
                }
              }
            } catch (e2) {
              _parseAndAddServer(body, groupName);
            }
          }
          return true;
        }
      } else {
        // Direct link parsing
        _parseAndAddServer(trimmed, 'Мои сервера');
        return true;
      }
    } catch (e) {
      debugPrint('Error adding subscription: $e');
    }
    return false;
  }

  void _parseAndAddServer(String config, String group) {
    // Ручная обработка Hysteria2, так как встроенный парсер может её не поддерживать
    if (config.startsWith('hysteria2://') || config.startsWith('hy2://')) {
      String name = 'Hysteria2 Server';
      if (config.contains('#')) {
        name = Uri.decodeComponent(config.split('#').last);
      } else if (config.contains('?')) {
        final query = Uri.parse(config).queryParameters;
        if (query.containsKey('remark')) name = query['remark']!;
      }

      addServer(
        ServerInfo(
          name: name,
          protocol: 'Hysteria2',
          ping: 0,
          group: group,
          config: config,
        ),
      );
      return;
    }

    try {
      final v2rayURL = FlutterV2ray.parseFromURL(config);
      final protocol = config.split('://').first.toUpperCase();

      addServer(
        ServerInfo(
          name: v2rayURL.remark.isEmpty ? 'New Server' : v2rayURL.remark,
          protocol: protocol,
          ping: 0,
          group: group,
          config: v2rayURL.getFullConfiguration(),
        ),
      );
    } catch (e) {
      String name = 'New Server';
      String protocol = 'VLESS';

      if (config.contains('#')) {
        name = Uri.decodeComponent(config.split('#').last);
      }

      if (config.startsWith('vless://'))
        protocol = 'VLESS';
      else if (config.startsWith('vmess://'))
        protocol = 'VMESS';
      else if (config.startsWith('ss://'))
        protocol = 'Shadowsocks';
      else if (config.startsWith('trojan://'))
        protocol = 'Trojan';
      else if (config.startsWith('hysteria2://') || config.startsWith('hy2://'))
        protocol = 'Hysteria2';
      else if (config.startsWith('wireguard://'))
        protocol = 'Wireguard';
      else if (config.contains('://')) {
        protocol = config.split('://').first.toUpperCase();
      }

      addServer(
        ServerInfo(
          name: name,
          protocol: protocol,
          ping: 0,
          group: group,
          config: config,
        ),
      );
    }
  }

  VpnProvider() {
    _loadServers();
    _generateHwid();
    _initV2ray();
  }

  Future<void> _saveServers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/servers.json');
      final data = {
        'servers': _servers.map((s) => s.toJson()).toList(),
        'settings': _settings.toJson(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving servers: $e');
    }
  }

  Future<void> _loadServers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/servers.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map) {
          if (data['servers'] != null) {
            _servers.clear();
            _servers.addAll(
              (data['servers'] as List)
                  .map((s) => ServerInfo.fromJson(s))
                  .toList(),
            );
          }
          if (data['settings'] != null) {
            _settings = VpnSettings.fromJson(data['settings']);
          }
        } else if (data is List) {
          _servers.clear();
          _servers.addAll(data.map((s) => ServerInfo.fromJson(s)).toList());
        }

        if (_servers.isNotEmpty && _selectedServer == null) {
          _selectedServer = _servers.first;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading servers: $e');
    }
  }

  Future<void> _generateHwid() async {
    final deviceInfo = DeviceInfoPlugin();
    String rawId = "fallback-id";

    try {
      _locale = Platform.localeName.split('.').first;
      _osVersion = Platform.operatingSystemVersion;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceModel = androidInfo.model;
        rawId = "${androidInfo.model}-${androidInfo.id}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;
        rawId = iosInfo.identifierForVendor ?? "ios-fallback";
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        _deviceModel = winInfo.computerName;
        rawId = "${winInfo.computerName}-${winInfo.numberOfCores}";
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        _deviceModel = linuxInfo.name;
        rawId = linuxInfo.machineId ?? "linux-fallback";
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        _deviceModel = macInfo.model;
        rawId = macInfo.systemGUID ?? "macos-fallback";
      }
    } catch (e) {
      rawId = "error-generating-id";
    }

    // Hash the raw ID to make it look like a professional HWID
    final bytes = utf8.encode(rawId);
    final hash = sha256
        .convert(bytes)
        .toString()
        .toUpperCase()
        .substring(0, 20);

    // Format it: XXXX-XXXX-XXXX-XXXX
    _hwid = hash
        .replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)}-")
        .substring(0, 19);
    notifyListeners();
  }

  VpnStatus get status => _status;
  ServerInfo? get selectedServer => _selectedServer;

  void toggleConnection() async {
    if (_selectedServer == null) return;

    if (!_v2rayInitialized) {
      debugPrint('V2Ray not initialized yet. Waiting...');
      return;
    }

    if (_status == VpnStatus.disconnected) {
      // Check for VPN permission on Android
      if (Platform.isAndroid) {
        debugPrint('Requesting VPN permission...');
        final hasPermission = await flutterV2ray.requestPermission();
        debugPrint('VPN permission result: $hasPermission');
        if (!hasPermission) return;
      }

      _status = VpnStatus.connecting;
      notifyListeners();

      try {
        // Prepare routing rules if using a full config
        // For simplicity with flutter_v2ray_plus, we use startVless 
        // but we should check if it supports app filtering.
        // Most forks support passing bypass/allow apps via a separate method or in start parameters.
        
        await flutterV2ray.startVless(
          remark: _selectedServer!.name,
          config: _selectedServer!.config,
        );
      } catch (e) {
        debugPrint('Error starting VPN: $e');
        _status = VpnStatus.disconnected;
        notifyListeners();
      }
    } else {
      await flutterV2ray.stopVless();
      _status = VpnStatus.disconnected;
      _stopTimer();
      notifyListeners();
    }
  }

  bool _pingInProgress = false;

  void _startTimer() {
    _duration = Duration.zero;
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration = Duration(seconds: _duration.inSeconds + 1);
      _checkServerPingPeriodically();
      notifyListeners();
    });
  }

  Future<void> _checkServerPingPeriodically() async {
    if (_pingInProgress || _selectedServer == null) return;
    _pingInProgress = true;
    try {
      final ping = await flutterV2ray
          .getServerDelay(config: _selectedServer!.config)
          .timeout(const Duration(seconds: 2));
      if (_selectedServer != null) {
        final index = _servers.indexWhere(
          (s) => s.config == _selectedServer!.config && s.name == _selectedServer!.name,
        );
        if (index != -1) {
          final updated = ServerInfo(
            name: _selectedServer!.name,
            country: _selectedServer!.country,
            protocol: _selectedServer!.protocol,
            ping: ping,
            group: _selectedServer!.group,
            config: _selectedServer!.config,
          );
          _servers[index] = updated;
          _selectedServer = updated;
          notifyListeners();
          _saveServers();
        }
      }
    } catch (_) {}
    _pingInProgress = false;
  }

  void _stopTimer() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
    _duration = Duration.zero;
  }

  String _formatSpeed(int bytes) {
    if (bytes <= 0) return "0 B/s";
    const units = ["B/s", "KB/s", "MB/s", "GB/s"];
    int i = (log(bytes) / log(1024)).floor();
    return "${(bytes / pow(1024, i)).toStringAsFixed(1)} ${units[i]}";
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }

  final Map<String, String> _groupSources = {};
  Map<String, String> get groupSources => _groupSources;

  final Set<String> _pingingServers = {};
  Set<String> get pingingServers => _pingingServers;

  String _serverKey(ServerInfo server) => '${server.config}::${server.name}';

  Future<void> checkServerPing(ServerInfo server) async {
    final key = _serverKey(server);
    _pingingServers.add(key);
    notifyListeners();
    try {
      final ping = await flutterV2ray
          .getServerDelay(config: server.config)
          .timeout(const Duration(seconds: 5));
      final index = _servers.indexWhere(
        (s) => s.config == server.config && s.name == server.name,
      );
      if (index != -1) {
        _servers[index] = ServerInfo(
          name: server.name,
          country: server.country,
          protocol: server.protocol,
          ping: ping,
          group: server.group,
          config: server.config,
        );
        notifyListeners();
        _saveServers();
      }
    } catch (e) {
      debugPrint('Error checking ping: $e');
      final index = _servers.indexWhere(
        (s) => s.config == server.config && s.name == server.name,
      );
      if (index != -1) {
        _servers[index] = ServerInfo(
          name: server.name,
          country: server.country,
          protocol: server.protocol,
          ping: -1,
          group: server.group,
          config: server.config,
        );
        notifyListeners();
      }
    }
    _pingingServers.remove(key);
    notifyListeners();
  }

  Future<void> checkGroupPing(String groupName) async {
    final groupServers = _servers.where((s) => s.group == groupName).toList();
    for (var server in groupServers) {
      await checkServerPing(server);
    }
  }

  Future<void> syncGroup(String groupName) async {
    final url = _groupSources[groupName];
    if (url != null) {
      // Remove old servers of this group
      _servers.removeWhere((s) => s.group == groupName);
      await addSubscription(url);
      notifyListeners();
    }
  }

  void selectServer(ServerInfo server) {
    _selectedServer = server;
    if (_status == VpnStatus.connected) {
      // Reconnect if already connected
      toggleConnection(); // Disconnect
      toggleConnection(); // Reconnect
    }
    notifyListeners();
  }
}
