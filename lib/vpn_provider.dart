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
  String splitMode;
  bool adDisabled;
  bool killSwitch;
  bool autoStart;
  String geoipUrl;
  String geositeUrl;
  int geoipUpdatedAt;
  int geositeUpdatedAt;
  bool observatoryEnabled;
  String observatoryGroup;
  int observatoryInterval;
  bool observatoryAutoSwitch;

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
    this.killSwitch = false,
    this.autoStart = false,
    this.geoipUrl = '',
    this.geositeUrl = '',
    this.geoipUpdatedAt = 0,
    this.geositeUpdatedAt = 0,
    this.observatoryEnabled = false,
    this.observatoryGroup = '',
    this.observatoryInterval = 60,
    this.observatoryAutoSwitch = true,
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
    'killSwitch': killSwitch,
    'autoStart': autoStart,
    'geoipUrl': geoipUrl,
    'geositeUrl': geositeUrl,
    'geoipUpdatedAt': geoipUpdatedAt,
    'geositeUpdatedAt': geositeUpdatedAt,
    'observatoryEnabled': observatoryEnabled,
    'observatoryGroup': observatoryGroup,
    'observatoryInterval': observatoryInterval,
    'observatoryAutoSwitch': observatoryAutoSwitch,
  };

  VpnSettings copyWith({
    int? socksPort,
    int? httpPort,
    bool? bypassLan,
    String? themeMode,
    String? language,
    List<String>? allowedApps,
    List<String>? excludedApps,
    List<String>? proxyDomains,
    List<String>? directDomains,
    String? splitMode,
    bool? adDisabled,
    bool? killSwitch,
    bool? autoStart,
    String? geoipUrl,
    String? geositeUrl,
    int? geoipUpdatedAt,
    int? geositeUpdatedAt,
    bool? observatoryEnabled,
    String? observatoryGroup,
    int? observatoryInterval,
    bool? observatoryAutoSwitch,
  }) => VpnSettings(
    socksPort: socksPort ?? this.socksPort,
    httpPort: httpPort ?? this.httpPort,
    bypassLan: bypassLan ?? this.bypassLan,
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    allowedApps: allowedApps ?? this.allowedApps,
    excludedApps: excludedApps ?? this.excludedApps,
    proxyDomains: proxyDomains ?? this.proxyDomains,
    directDomains: directDomains ?? this.directDomains,
    splitMode: splitMode ?? this.splitMode,
    adDisabled: adDisabled ?? this.adDisabled,
    killSwitch: killSwitch ?? this.killSwitch,
    autoStart: autoStart ?? this.autoStart,
    geoipUrl: geoipUrl ?? this.geoipUrl,
    geositeUrl: geositeUrl ?? this.geositeUrl,
    geoipUpdatedAt: geoipUpdatedAt ?? this.geoipUpdatedAt,
    geositeUpdatedAt: geositeUpdatedAt ?? this.geositeUpdatedAt,
    observatoryEnabled: observatoryEnabled ?? this.observatoryEnabled,
    observatoryGroup: observatoryGroup ?? this.observatoryGroup,
    observatoryInterval: observatoryInterval ?? this.observatoryInterval,
    observatoryAutoSwitch: observatoryAutoSwitch ?? this.observatoryAutoSwitch,
  );

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
    killSwitch: json['killSwitch'] ?? false,
    autoStart: json['autoStart'] ?? false,
    geoipUrl: json['geoipUrl'] ?? '',
    geositeUrl: json['geositeUrl'] ?? '',
    geoipUpdatedAt: json['geoipUpdatedAt'] ?? 0,
    geositeUpdatedAt: json['geositeUpdatedAt'] ?? 0,
    observatoryEnabled: json['observatoryEnabled'] ?? false,
    observatoryGroup: json['observatoryGroup'] ?? '',
    observatoryInterval: json['observatoryInterval'] ?? 60,
    observatoryAutoSwitch: json['observatoryAutoSwitch'] ?? true,
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

  final List<ServerInfo> _servers = [];

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
    final obsChanged =
        _settings.observatoryEnabled != newSettings.observatoryEnabled ||
        _settings.observatoryGroup != newSettings.observatoryGroup ||
        _settings.observatoryInterval != newSettings.observatoryInterval;
    _settings = newSettings;
    _saveServers();
    if (obsChanged) _restartObservatory();
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
        final groupName = uri.host + uri.path;

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
    _loadServers().then((_) => _autoConnect());
    _generateHwid();
    _initV2ray();
  }

  Future<void> _autoConnect() async {
    if (_settings.autoStart && _selectedServer != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (_status == VpnStatus.disconnected && _selectedServer != null) {
        toggleConnection();
      }
    }
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
      _docDir = directory.path;
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
        _restartObservatory();
      }
    } catch (e) {
      debugPrint('Error loading servers: $e');
    }
  }

  Future<bool> downloadGeoFile(String url, String type) async {
    if (url.isEmpty) return false;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) return false;
      final path = type == 'geoip' ? geoipDatPath : geositeDatPath;
      await File(path).writeAsBytes(response.bodyBytes);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      updateSettings(_settings.copyWith(
        geoipUpdatedAt: type == 'geoip' ? now : _settings.geoipUpdatedAt,
        geositeUpdatedAt: type == 'geosite' ? now : _settings.geositeUpdatedAt,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _classifyRules(List<String> entries, List<String> domains, List<String> ips) {
    for (var entry in entries) {
      if (entry.startsWith('geoip:')) {
        ips.add(entry);
      } else if (entry.startsWith('geosite:')) {
        domains.add(entry);
      } else if (entry.startsWith('regexp:')) {
        domains.add(entry);
      } else if (entry.contains('/')) {
        ips.add(entry);
      } else {
        domains.add(entry);
      }
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
        String config = _selectedServer!.config;
        if (_settings.killSwitch || _settings.proxyDomains.isNotEmpty || _settings.directDomains.isNotEmpty) {
          config = _injectRouting(config);
        }

        await flutterV2ray.startVless(
          remark: _selectedServer!.name,
          config: config,
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

  String _injectRouting(String rawConfig) {
    try {
      final parsed = json.decode(rawConfig);
      if (parsed is! Map<String, dynamic>) return rawConfig;

      final outbounds = List<Map<String, dynamic>>.from(parsed['outbounds'] ?? []);
      final routing = Map<String, dynamic>.from(parsed['routing'] ?? {});
      final rules = List<Map<String, dynamic>>.from(routing['rules'] ?? []);

      parsed['routing'] = routing;

      // Point V2Ray to our geoip/geosite files
      if (_settings.geoipUrl.isNotEmpty || _settings.geositeUrl.isNotEmpty) {
        if (_docDir.isNotEmpty) {
          parsed['v2ray.dat.asset.path'] = _docDir;
        }
      }

      // Ensure a direct/freedom outbound exists for bypass rules
      final hasDirect = outbounds.any((o) => o['tag'] == 'direct');
      if (_settings.directDomains.isNotEmpty && !hasDirect) {
        outbounds.add({'protocol': 'freedom', 'tag': 'direct'});
      }

      // Find proxy outbound tag
      String proxyTag = '';
      for (var ob in outbounds) {
        final tag = ob['tag'] as String?;
        if (tag == null || tag == 'direct' || tag == 'blocked' || tag == 'dns') continue;
        proxyTag = tag;
        break;
      }
      if (proxyTag.isEmpty) {
        proxyTag = 'proxy';
        if (outbounds.isNotEmpty) {
          outbounds[0]['tag'] = proxyTag;
        }
      }

      // Direct domains (bypass proxy)
      if (_settings.directDomains.isNotEmpty) {
        final dirDomains = <String>[];
        final dirIps = <String>[];
        _classifyRules(_settings.directDomains, dirDomains, dirIps);
        if (dirDomains.isNotEmpty) {
          rules.add({'type': 'field', 'domain': dirDomains, 'outboundTag': 'direct'});
        }
        if (dirIps.isNotEmpty) {
          rules.add({'type': 'field', 'ip': dirIps, 'outboundTag': 'direct'});
        }
      }

      // Proxy domains (explicit proxy, before kill switch catch-all)
      if (_settings.proxyDomains.isNotEmpty) {
        final prxDomains = <String>[];
        final prxIps = <String>[];
        _classifyRules(_settings.proxyDomains, prxDomains, prxIps);
        if (prxDomains.isNotEmpty) {
          rules.add({'type': 'field', 'domain': prxDomains, 'outboundTag': proxyTag});
        }
        if (prxIps.isNotEmpty) {
          rules.add({'type': 'field', 'ip': prxIps, 'outboundTag': proxyTag});
        }
      }

      // Kill switch (block everything else)
      if (_settings.killSwitch) {
        outbounds.add({'protocol': 'blackhole', 'tag': 'blocked'});
        rules.add({'type': 'field', 'ip': ['0.0.0.0/0', '::/0'], 'outboundTag': 'blocked'});
      }

      parsed['outbounds'] = outbounds;
      routing['rules'] = rules;
      return json.encode(parsed);
    } catch (_) {}
    return rawConfig;
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

  Timer? _observatoryTimer;

  List<String> get observatoryGroupNames =>
      _servers.map((s) => s.group).toSet().toList()..sort();

  void _restartObservatory() {
    _stopObservatory();
    if (!_settings.observatoryEnabled) return;
    if (_settings.observatoryGroup.isEmpty) return;
    final groupServers =
        _servers.where((s) => s.group == _settings.observatoryGroup).toList();
    if (groupServers.isEmpty) return;

    _observatoryTimer = Timer.periodic(
      Duration(seconds: _settings.observatoryInterval),
      (_) => _runObservatory(),
    );
    // Run immediately
    _runObservatory();
  }

  void _stopObservatory() {
    _observatoryTimer?.cancel();
    _observatoryTimer = null;
  }

  Future<void> _runObservatory() async {
    final group = _settings.observatoryGroup;
    if (group.isEmpty) return;
    final servers = _servers.where((s) => s.group == group).toList();
    if (servers.length < 2) return;

    // Ping all servers in the group in parallel
    final results = await Future.wait(servers.map((s) async {
      final key = _serverKey(s);
      _pingingServers.add(key);
      notifyListeners();
      try {
        final ping = await flutterV2ray
            .getServerDelay(config: s.config)
            .timeout(const Duration(seconds: 4));
        return (server: s, ping: ping);
      } catch (_) {
        return (server: s, ping: -1);
      }
    }));

    // Update pings
    for (final result in results) {
      final idx = _servers.indexWhere(
        (s) => s.config == result.server.config,
      );
      if (idx != -1) {
        _servers[idx] = ServerInfo(
          name: result.server.name,
          country: result.server.country,
          protocol: result.server.protocol,
          ping: result.ping,
          group: result.server.group,
          config: result.server.config,
        );
      }
      _pingingServers.remove(_serverKey(result.server));
    }

    // Auto-switch to best ping
    if (_settings.observatoryAutoSwitch && _status == VpnStatus.connected) {
      final best = results
          .where((r) => r.ping > 0)
          .reduce((a, b) => a.ping < b.ping ? a : b);
      if (best.ping > 0 && best.server.config != _selectedServer?.config) {
        debugPrint(
            'Observatory: switching to ${best.server.name} (${best.ping}ms)');
        _selectedServer = best.server;
        _saveServers();
        notifyListeners();
        // Reconnect to new server
        toggleConnection(); // disconnect
        toggleConnection(); // connect
        return;
      }
    }

    _saveServers();
    notifyListeners();
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
    _stopObservatory();
    super.dispose();
  }

  final Map<String, String> _groupSources = {};
  Map<String, String> get groupSources => _groupSources;

  final Set<String> _pingingServers = {};
  Set<String> get pingingServers => _pingingServers;

  String _docDir = '';
  String get geoipDatPath => '$_docDir/geoip.dat';
  String get geositeDatPath => '$_docDir/geosite.dat';

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

  Future<({bool ok, int count})> syncGroup(String groupName) async {
    final url = _groupSources[groupName];
    if (url != null) {
      _servers.removeWhere((s) => s.group == groupName);
      if (_selectedServer?.group == groupName) {
        _selectedServer = null;
      }
      final ok = await addSubscription(url);
      notifyListeners();
      return (ok: ok, count: _servers.where((s) => s.group == groupName).length);
    }
    return (ok: false, count: 0);
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
