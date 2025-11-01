import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String? _q;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getPests(q: _q);
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = 'Lỗi tải danh mục: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSubmit(String v) {
    _q = v.trim().isEmpty ? null : v.trim();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Durian Pest')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB9F6CA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  const Text('Chào mừng đến ứng dụng phân loại sâu hại sầu riêng.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm sâu hại…',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: _onSubmit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Danh mục sâu hại', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),

            if (!_loading && _items.isEmpty)
              Text(_q == null ? 'Chưa có dữ liệu.' : 'Không tìm thấy với từ khóa: $_q'),

            // Danh sách có khoảng cách giữa các card:
            ..._items.map((e) {
              final code = (e['Code'] ?? '').toString();
              final name = (e['TenThuong'] ?? code).toString();
              final sci  = (e['TenKhoaHoc'] ?? '').toString();
              final desc = (e['MoTaNgan'] ?? '').toString();
              final photo = ((e['Photos'] ?? []) as List).isNotEmpty
                  ? ((e['Photos'] as List).first as String)
                  : null;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6), // <-- tạo khoảng cách
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: photo == null
                      ? const CircleAvatar(child: Icon(Icons.bug_report))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photo.startsWith('http')
                                ? photo
                                : '${ApiService.base}$photo',
                            width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.bug_report)),
                          ),
                        ),
                  title: Text(name),
                  subtitle: Text(
                    sci.isNotEmpty ? '$sci\n$desc' : desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, '/detail', arguments: code),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
