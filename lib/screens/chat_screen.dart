// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/section_block.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  /// Cấu trúc tin nhắn trong chat
  /// role: 'user' | 'bot'
  /// text: nội dung text
  /// detail/drugs: dữ liệu giàu (khi là kết quả tra sâu)
  final List<Map<String, dynamic>> _messages = [];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _pushMessage(Map<String, dynamic> msg) {
    setState(() => _messages.add(msg));
    // auto scroll cuối danh sách
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty || _sending) return;

    // hiển thị tin nhắn người dùng
    _pushMessage({'role': 'user', 'text': raw});
    _ctrl.clear();

    // BOT xử lý
    setState(() => _sending = true);
    try {
      final lower = raw.toLowerCase();

      // 1) Chào hỏi đơn giản
      const greetings = ['xin chào', 'chào', 'hello', 'hi', 'alo'];
      if (greetings.any((g) => lower.contains(g))) {
        _pushMessage({
          'role': 'bot',
          'text': 'Chào bạn 👋! Mình là trợ lý sâu hại sầu riêng. '
              'Bạn có thể nhập tên sâu (vd: rệp sáp, bọ trĩ, helopeltis) '
              'hoặc mô tả triệu chứng để mình tra cứu nhé.'
        });
        return;
      }

      // 2) Tra cứu sâu hại theo từ khóa => trả chi tiết + thuốc gợi ý
      final items = await ApiService.getPests(q: raw);
      if (items.isNotEmpty) {
        final first = Map<String, dynamic>.from(items.first);
        final code = (first['Code'] ?? '').toString();
        final detail = await ApiService.getPest(code);
        final drugs = await ApiService.getDrugsForPest(code);

        _pushMessage({
          'role': 'bot',
          'text': 'Mình tìm thấy **${detail?['TenThuong'] ?? code}**. '
              'Dưới đây là tóm tắt và thuốc gợi ý.',
          'detail': detail,
          'drugs': drugs,
        });
        return;
      }

      // 3) Mặc định – thông báo bận/đang update
      _pushMessage({
        'role': 'bot',
        'text':
            'Hệ thống đang bận, vui lòng thử lại sau (chương trình đang được update).',
      });
    } catch (e) {
      _pushMessage({
        'role': 'bot',
        'text': 'Có lỗi khi xử lý: $e',
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat tư vấn')),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                final hasRich = m.containsKey('detail');

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isUser
                            ? theme.colorScheme.primary.withValues(alpha: 0.10)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: theme.dividerColor.withOpacity(0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text cơ bản
                            if (m['text'] != null)
                              SelectableText(
                                m['text'].toString(),
                                style: theme.textTheme.bodyMedium,
                              ),
                            // Nội dung giàu: chi tiết sâu + thuốc
                            if (hasRich) ..._buildRichContent(m, context),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Thanh nhập chat
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText:
                            'Nhập “xin chào”, hoặc tên sâu/triệu chứng để tra cứu…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dựng phần nội dung giàu (khi có chi tiết sâu và thuốc gợi ý)
  List<Widget> _buildRichContent(
      Map<String, dynamic> msg, BuildContext context) {
    final theme = Theme.of(context);
    final detail = msg['detail'] as Map<String, dynamic>?;
    final drugsRaw = msg['drugs'] as List?;
    final drugs = (drugsRaw ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    final name = (detail?['TenThuong'] ?? detail?['Code'])?.toString();
    final moTa = (detail?['MoTaNgan'] ?? '').toString();
    final ipm = (detail?['BienPhapIPMDecoded'] ?? detail?['BienPhapIPM'])
            as Map? ??
        {};

    return [
      const SizedBox(height: 8),
      if (name != null)
        SectionBlock(title: 'Kết quả', child: Text(name)),
      if (moTa.isNotEmpty)
        SectionBlock(
          title: 'Mô tả',
          child: Text(moTa),
        ),
      // IPM (nếu có)
      if (ipm.isNotEmpty)
        ...ipm.entries.map((e) {
          final k = e.key.toString();
          final v = (e.value is List) ? (e.value as List) : const [];
          return SectionBlock(
            title: k,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: v
                  .map<Widget>(
                    (x) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(x.toString())),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }),

      // Thuốc gợi ý
      SectionBlock(
        title: 'Thuốc gợi ý (tham khảo)',
        child: drugs.isEmpty
            ? const Text('Chưa có dữ liệu.')
            : Column(
                children: drugs.map((d) {
                  final ten = (d['Ten'] ?? d['Code'])?.toString() ?? '';
                  final hoatChat = (d['HoatChat'] ?? '').toString();
                  final nhom = (d['Nhom'] ?? '').toString();
                  final hang = (d['Hang'] ?? '').toString();

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                          // ignore: deprecated_member_use
                          color: theme.dividerColor.withOpacity(0.3)),
                    ),
                    child: ListTile(
                      title: Text(ten),
                      subtitle: Text(
                        [
                          if (hoatChat.isNotEmpty) hoatChat,
                          if (nhom.isNotEmpty) nhom,
                          if (hang.isNotEmpty) 'Hãng: $hang',
                        ].join(' • '),
                      ),
                      trailing: const Icon(Icons.info_outline),
                      onTap: () => _showDrugDetailSheet(context, d),
                    ),
                  );
                }).toList(),
              ),
      ),
      const SizedBox(height: 6),
      Text(
        'Lưu ý: Thông tin chỉ tham khảo. Tuân thủ nhãn thuốc, PHI và quy định địa phương.',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      ),
    ];
  }

  void _showDrugDetailSheet(BuildContext context, Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final ten = (d['Ten'] ?? d['Code'])?.toString() ?? '';
        final hoatChat = (d['HoatChat'] ?? '').toString();
        final nhom = (d['Nhom'] ?? '').toString();
        final hang = (d['Hang'] ?? '').toString();
        final huongDan = (d['HuongDan'] ?? '').toString();
        final ghiChu = (d['GhiChu'] ?? '').toString();

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ten, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (hoatChat.isNotEmpty)
                  Text('Hoạt chất: $hoatChat',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                if (nhom.isNotEmpty)
                  Text('Nhóm: $nhom',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                if (hang.isNotEmpty)
                  Text('Hãng: $hang',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 12),
                if (huongDan.isNotEmpty)
                  SectionBlock(
                    title: 'Hướng dẫn sử dụng',
                    child: Text(huongDan),
                  ),
                if (ghiChu.isNotEmpty)
                  SectionBlock(
                    title: 'Ghi chú',
                    child: Text(ghiChu),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
