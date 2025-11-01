// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
static const _host = '192.168.1.206';
static const _port = 8000;
static const base = 'http://$_host:$_port';

  /// Thêm alias 'baseUrl' cho các file khác đang gọi baseUrl
  static const String baseUrl = base;

  static Uri _u(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$base$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  // ---------------- PESTS ----------------
  static Future<List<Map<String, dynamic>>> getPests({String? q}) async {
    final uri = _u('/pests', (q != null && q.trim().isNotEmpty) ? {'q': q} : null);
    final r = await http.get(uri).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('GET /pests failed ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<Map<String, dynamic>?> getPest(String code) async {
    final r = await http
        .get(_u('/pests/$code'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('GET /pests/$code failed ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final p = data['pest'];
    return p == null ? null : Map<String, dynamic>.from(p as Map);
  }

  // ---------------- DRUGS ----------------
  static Future<List<Map<String, dynamic>>> getDrugs() async {
    final r = await http.get(_u('/drugs')).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('GET /drugs failed ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getDrugsForPest(String code) async {
    final r = await http
        .get(_u('/pests/$code/drugs'))
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('GET /pests/$code/drugs failed ${r.statusCode}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? const [];
    return items
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ---------------- CLASSIFY (top-k) ----------------
  /// Trả list:
  /// [{"prediction":{"code":"..","prob":..},"detail":{...},"drugs":[...]}]
  static Future<List<Map<String, dynamic>>> classify(Uint8List bytes) async {
    final req = http.MultipartRequest('POST', _u('/classify'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'photo.jpg'));
    final streamed = await req.send().timeout(const Duration(seconds: 25));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw Exception('POST /classify failed ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    return results
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // ---------------- AUTH ----------------
  static Future<bool> register(String username, String password) async {
    final r = await http
        .post(
          _u('/auth/register'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'username': username, 'password': password},
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) return false;
    final ok = (jsonDecode(r.body) as Map<String, dynamic>)['ok'] == true;
    return ok;
  }

  static Future<bool> login(String username, String password) async {
    final r = await http
        .post(
          _u('/auth/login'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'username': username, 'password': password},
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) return false;
    final ok = (jsonDecode(r.body) as Map<String, dynamic>)['ok'] == true;
    return ok;
  }

  // ---------------- HEALTH ----------------
  static Future<bool> health() async {
    try {
      final r = await http.get(_u('/health')).timeout(const Duration(seconds: 6));
      if (r.statusCode != 200) return false;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return data['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
