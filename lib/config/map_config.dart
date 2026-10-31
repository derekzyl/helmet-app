import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapConfig {
  /// Carto basemap key from --dart-define=MAP_API_KEY=... or app/.env
  static String get apiKey {
    const fromDefine = String.fromEnvironment('MAP_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    try {
      return dotenv.env['MAP_API_KEY'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String rasterUrl({bool dark = true}) {
    final key = apiKey;
    final style = dark ? 'dark_all' : 'rastertiles/voyager';
    final base = dark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    if (key.isEmpty) return base;
    if (dark) {
      return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png?key=$key';
    }
    return 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png?key=$key';
  }

  static String get vectorStyleUrl {
    final key = apiKey;
    if (key.isEmpty) {
      return 'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';
    }
    return 'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json?key=$key';
  }

  // ignore: unused_element
  static String get _styleHint => 'voyager';
}
