// lib/screens/detect_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked;
  bool _loading = false;
  String? _error;

  /// [{ prediction:{code,prob}, detail:{...}, drugs:[...] }, ...]
  List<Map<String, dynamic>> _results = [];

  Future<void> _pick(ImageSource src) async {
    setState(() => _error = null);
    try {
      final x = await _picker.pickImage(source: src, imageQuality: 95);
      if (x == null) return;
      setState(() {
        _picked = x;
        _results = [];
      });
    } catch (e) {
      setState(() => _error = 'Không mở được camera/thư viện: $e');
    }
  }

  Future<void> _analyze() async {
    if (_picked == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final bytes = await _picked!.readAsBytes(); // Uint8List
      // GỌI HÀM ĐÚNG TÊN Ở ApiService
      final res = await ApiService.classify(bytes);
      // ép kiểu an toàn
      final list = (res).map<Map<String, dynamic>>(
        (e) => Map<String, dynamic>.from(e as Map),
      ).toList();
      setState(() => _results = list);
    } catch (e) {
      setState(() => _error = 'Lỗi phân tích: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Quét AI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Nếu phiên bản Flutter của bạn chưa có withValues,
                // thay dòng dưới bằng: Colors.red.withOpacity(0.1)
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Card(
            elevation: 0,
            // Nếu chưa có withValues, thay bằng withOpacity(0.08)
            color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ảnh nguồn', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                        color: Colors.white,
                      ),
                      child: _picked == null
                          ? const Text('Chưa chọn ảnh')
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_picked!.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.gallery),
                          icon: const Icon(Icons.image),
                          label: const Text('Chọn ảnh'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pick(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Chụp ảnh'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: (_picked != null && !_loading) ? _analyze : null,
                    icon: const Icon(Icons.bolt),
                    label: _loading
                        ? const Text('Đang phân tích…')
                        : const Text('Phân tích'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text('Kết quả gợi ý (top-k)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_results.isEmpty && !_loading)
            const Text('Chưa có kết quả. Hãy chọn/chụp ảnh rồi bấm Phân tích.'),
          ..._results.map((r) {
            final pred = Map<String, dynamic>.from((r['prediction'] ?? {}) as Map? ?? {});
            final detail = Map<String, dynamic>.from((r['detail'] ?? {}) as Map? ?? {});
            final drugsRaw = (r['drugs'] as List?) ?? const [];
            final drugs = drugsRaw.map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            ).toList();

            final name = (detail['TenThuong'] ??
                    detail['Code'] ??
                    pred['code'] ??
                    '')
                .toString();
            final prob = ((pred['prob'] ?? 0) as num).toDouble();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6), // tách thẻ
              child: ListTile(
                title: Text('$name • ${(prob * 100).toStringAsFixed(1)}%'),
                subtitle: drugs.isEmpty
                    ? const Text('Chưa có thuốc gợi ý.')
                    : Text('Thuốc: ${drugs.map((d) => d['Ten']).whereType<String>().join(', ')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final code = (detail['Code'] ?? pred['code'])?.toString();
                  if (code != null && code.isNotEmpty) {
                    Navigator.pushNamed(context, '/detail', arguments: code);
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
