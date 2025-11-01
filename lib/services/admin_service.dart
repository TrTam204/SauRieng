// lib/services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AdminService {
  static Future<Map<String, String>> _headers() async {
    final sp = await SharedPreferences.getInstance();
    final username = sp.getString('username');
    return {
      'X-User': username ?? '',
    };
  }

  static Future<Map<String, dynamic>> me() async {
    final h = await _headers();
    final uri = Uri.parse('${ApiService.baseUrl}/auth/me');
    final r = await http.get(uri, headers: h).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('GET /auth/me ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<int> createPest({
    required String code,
    String tenThuong = '',
    String tenKhoaHoc = '',
    String moTaNgan = '',
    String? nhanBietJson,
    String? bienPhapIpmJson,
    String tacHai = '',
  }) async {
    final h = await _headers();
    final uri = Uri.parse('${ApiService.baseUrl}/admin/pests');
    final r = await http.post(uri, headers: h, body: {
      'Code': code,
      'TenThuong': tenThuong,
      'TenKhoaHoc': tenKhoaHoc,
      'MoTaNgan': moTaNgan,
      if (nhanBietJson != null) 'NhanBiet': nhanBietJson,
      if (bienPhapIpmJson != null) 'BienPhapIPM': bienPhapIpmJson,
      'TacHai': tacHai,
    }).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('POST /admin/pests ${r.statusCode} ${r.body}');
    return (jsonDecode(r.body)['id'] as num).toInt();
  }

  static Future<void> addPestPhoto(String code, String url) async {
    final h = await _headers();
    final uri = Uri.parse('${ApiService.baseUrl}/admin/pests/$code/photos');
    final r = await http.post(uri, headers: h, body: {'url': url})
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('POST add photo ${r.statusCode}');
  }

  static Future<int> createDrug({
    required String ten,
    String hoatChat = '',
    String nhom = '',
    String hang = '',
    String huongDan = '',
    String ghiChu = '',
  }) async {
    final h = await _headers();
    final uri = Uri.parse('${ApiService.baseUrl}/admin/drugs');
    final r = await http.post(uri, headers: h, body: {
      'Ten': ten,
      'HoatChat': hoatChat,
      'Nhom': nhom,
      'Hang': hang,
      'HuongDan': huongDan,
      'GhiChu': ghiChu,
    }).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('POST /admin/drugs ${r.statusCode} ${r.body}');
    return (jsonDecode(r.body)['id'] as num).toInt();
  }

  static Future<void> linkDrugToPest(String code, int drugId) async {
    final h = await _headers();
    final uri = Uri.parse('${ApiService.baseUrl}/admin/pests/$code/drugs');
    final r = await http.post(uri, headers: h, body: {'drug_id': '$drugId'})
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception('POST link drug ${r.statusCode}');
  }
}
