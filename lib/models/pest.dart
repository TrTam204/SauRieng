import 'dart:convert';

class Pest {
  final int id;
  final String code;
  final String tenThuong;
  final String? tenKhoaHoc;
  final String? moTaNgan;
  final List<String> photos;
  final List<String> nhanBiet;
  final Map<String, dynamic> ipm;
  final List<String> tacHai;

  Pest({
    required this.id,
    required this.code,
    required this.tenThuong,
    this.tenKhoaHoc,
    this.moTaNgan,
    this.photos = const [],
    this.nhanBiet = const [],
    this.ipm = const {},
    this.tacHai = const [],
  });

  static List<String> _asStrList(dynamic v) {
    if (v == null) return <String>[];
    if (v is List) return v.map((e) => '$e').toList();
    if (v is String && v.trim().isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is List) return d.map((e) => '$e').toList();
      } catch (_) {}
    }
    return <String>[];
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.trim().isNotEmpty) {
      try {
        final d = jsonDecode(v);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  factory Pest.fromJson(Map<String, dynamic> j) {
    return Pest(
      id: j['Id'] ?? j['id'] ?? 0,
      code: j['Code'] ?? j['code'] ?? '',
      tenThuong: j['TenThuong'] ?? j['tenThuong'] ?? '',
      tenKhoaHoc: j['TenKhoaHoc'] ?? j['tenKhoaHoc'],
      moTaNgan: j['MoTaNgan'] ?? j['moTaNgan'],
      photos: ((j['Photos'] ?? j['photos']) is List)
          ? List<String>.from((j['Photos'] ?? j['photos']))
          : _asStrList(j['Photos'] ?? j['photos']),
      nhanBiet: _asStrList(j['NhanBietDecoded'] ?? j['NhanBiet'] ?? j['nhanBiet']),
      ipm: _asMap(j['BienPhapIPMDecoded'] ?? j['BienPhapIPM'] ?? j['ipm']),
      tacHai: _asStrList(j['TacHaiDecoded'] ?? j['TacHai'] ?? j['tacHai']),
    );
  }
}
