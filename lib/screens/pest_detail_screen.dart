import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/pest.dart';
import '../widgets/section_block.dart';

class PestDetailScreen extends StatefulWidget {
  final String code;
  const PestDetailScreen({super.key, required this.code});

  @override
  State<PestDetailScreen> createState() => _PestDetailScreenState();
}

class _PestDetailScreenState extends State<PestDetailScreen> {
  Pest? _pest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getPest(widget.code);
      if (raw != null) {
        _pest = Pest.fromJson(raw);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tải chi tiết: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _pest;
    return Scaffold(
      appBar: AppBar(title: Text(p?.tenThuong ?? 'Chi tiết')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? const Center(child: Text('Không tìm thấy'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 220,
                        child: PageView(
                          children: (p.photos.isEmpty ? [''] : p.photos).map((u) {
                            if (u.isEmpty) {
                              return const Center(
                                  child: Icon(Icons.image_not_supported, size: 60));
                            }
                            final full = u.startsWith('http')
                                ? u
                                : "${ApiService.base}$u";
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: full,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(p.tenThuong, style: Theme.of(context).textTheme.headlineSmall),
                      if (p.tenKhoaHoc != null && p.tenKhoaHoc!.isNotEmpty)
                        Text(p.tenKhoaHoc!,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: Colors.black54)),
                      const SizedBox(height: 8),
                      if (p.moTaNgan != null)
                        Text(p.moTaNgan!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      SectionBlock(
                        title: 'Nhận biết',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (p.nhanBiet.isEmpty ? ['—'] : p.nhanBiet)
                              .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(child: Text(e)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      SectionBlock(
                        title: 'Tác hại',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (p.tacHai.isEmpty ? ['—'] : p.tacHai)
                              .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(child: Text(e)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      SectionBlock(
                        title: 'Biện pháp IPM',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: p.ipm.entries.map((kv) {
                            final k = kv.key;
                            final v = kv.value;
                            final list = v is List ? v : <dynamic>[];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(k, style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  ...list.map((e) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('– '),
                                            Expanded(child: Text('$e')),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
