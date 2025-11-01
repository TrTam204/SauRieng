import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/section_block.dart';
import '../app_router.dart';

class AdviceScreen extends StatefulWidget {
  const AdviceScreen({super.key});
  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  // Quan trọng: để kiểu rõ ràng, tránh suy luận thành Object
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _selectedCode;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _loading = true);
    try {
      final items = await ApiService.getPests();
      _items = items.cast<Map<String, dynamic>>();
    } catch (_) {
      _items = <Map<String, dynamic>>[];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDetail(String code) async {
    setState(() {
      _selectedCode = code;
      _detail = null;
      _loading = true;
    });
    try {
      final d = await ApiService.getPest(code);
      if (d != null) _detail = d;
    } catch (_) {
      _detail = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map ipm = (_detail?['BienPhapIPMDecoded'] ?? _detail?['BienPhapIPM']) as Map? ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Tư vấn IPM/Thuốc')),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ==== Dropdown đã FIX: dùng <String> + initialValue + items kiểu chặt ====
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCode,
                    hint: const Text('Chọn loài sâu hại'),
                    items: _items.map<DropdownMenuItem<String>>((it) {
                      final code = (it['Code'] ?? '').toString();
                      final name = (it['TenThuong'] ?? code).toString();
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) _loadDetail(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _detail == null
                        ? const Center(child: Text('Chưa chọn loài'))
                        : ListView(
                            children: [
                              const SectionBlock(
                                title: 'Khuyến cáo an toàn',
                                child: Text(
                                  'Chỉ tham khảo. Tuân thủ nhãn thuốc, thời gian cách ly (PHI), '
                                  'luân phiên hoạt chất (IRAC/FRAC), ưu tiên canh tác–sinh học–cơ giới trước hoá học.',
                                ),
                              ),
                              ...ipm.entries.map((e) {
                                final k = '${e.key}';
                                final v = (e.value is List) ? (e.value as List) : const [];
                                return SectionBlock(
                                  title: k,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: v.map<Widget>((x) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [const Text('• '), Expanded(child: Text('$x'))],
                                      ),
                                    )).toList(),
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              FilledButton.icon(
                                onPressed: _selectedCode == null
                                    ? null
                                    : () => Navigator.pushNamed(
                                          context, AppRouter.detail,
                                          arguments: _selectedCode!,
                                        ),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Xem chi tiết loài'),
                              ),
                            ],
                          ),
                  )
                ],
              ),
            ),
    );
  }
}
