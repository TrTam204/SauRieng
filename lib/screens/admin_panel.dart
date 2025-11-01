// lib/screens/admin_panel.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});
  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _tab = 0;

  // --- form thêm sâu
  final code = TextEditingController();
  final tenThuong = TextEditingController();
  final tenKhoaHoc = TextEditingController();
  final moTaNgan = TextEditingController();
  final tacHai = TextEditingController();
  final nhanBiet = TextEditingController(text: '["Triệu chứng 1","Triệu chứng 2"]');
  final ipm = TextEditingController(text: '{"Vật lý/cơ giới":["Biện pháp A"],"Hóa học":["Biện pháp B"]}');
  final photoUrl = TextEditingController();

  // --- form thêm thuốc
  final drugTen = TextEditingController();
  final drugHoatChat = TextEditingController();
  final drugNhom = TextEditingController();
  final drugHang = TextEditingController();
  final drugHuongDan = TextEditingController();
  final drugGhiChu = TextEditingController();

  // --- form gán thuốc
  final linkCode = TextEditingController();
  final linkDrugId = TextEditingController();

  bool busy = false;

  @override
  void dispose() {
    code.dispose(); tenThuong.dispose(); tenKhoaHoc.dispose();
    moTaNgan.dispose(); tacHai.dispose(); nhanBiet.dispose(); ipm.dispose();
    photoUrl.dispose();
    drugTen.dispose(); drugHoatChat.dispose(); drugNhom.dispose();
    drugHang.dispose(); drugHuongDan.dispose(); drugGhiChu.dispose();
    linkCode.dispose(); linkDrugId.dispose();
    super.dispose();
  }

  Future<void> _submitPest() async {
    setState(() => busy = true);
    try {
      // validate JSON fields if not empty
      String? nb, bp;
      if (nhanBiet.text.trim().isNotEmpty) {
        jsonDecode(nhanBiet.text); // validate
        nb = nhanBiet.text;
      }
      if (ipm.text.trim().isNotEmpty) {
        jsonDecode(ipm.text);
        bp = ipm.text;
      }
      final id = await AdminService.createPest(
        code: code.text.trim(),
        tenThuong: tenThuong.text.trim(),
        tenKhoaHoc: tenKhoaHoc.text.trim(),
        moTaNgan: moTaNgan.text.trim(),
        tacHai: tacHai.text.trim(),
        nhanBietJson: nb,
        bienPhapIpmJson: bp,
      );
      if (photoUrl.text.trim().isNotEmpty) {
        await AdminService.addPestPhoto(code.text.trim(), photoUrl.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo sâu thành công (Id=$id)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo sâu: $e')),
        );
      }
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _submitDrug() async {
    setState(() => busy = true);
    try {
      final id = await AdminService.createDrug(
        ten: drugTen.text.trim(),
        hoatChat: drugHoatChat.text.trim(),
        nhom: drugNhom.text.trim(),
        hang: drugHang.text.trim(),
        huongDan: drugHuongDan.text.trim(),
        ghiChu: drugGhiChu.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo thuốc thành công (Id=$id)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo thuốc: $e')),
        );
      }
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _submitLink() async {
    setState(() => busy = true);
    try {
      await AdminService.linkDrugToPest(
        linkCode.text.trim(),
        int.parse(linkDrugId.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gán thuốc cho sâu thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gán thuốc: $e')),
        );
      }
    } finally { if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng điều khiển Admin')),
      body: Column(
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Thêm Sâu')),
              ButtonSegment(value: 1, label: Text('Thêm Thuốc')),
              ButtonSegment(value: 2, label: Text('Gán Thuốc↔Sâu')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (_tab) {
                0 => _buildPestForm(),
                1 => _buildDrugForm(),
                _ => _buildLinkForm(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestForm() {
    return ListView(
      children: [
        _t('Mã Code', code),
        _t('Tên thường', tenThuong),
        _t('Tên khoa học', tenKhoaHoc),
        _t('Mô tả ngắn', moTaNgan, maxLines: 3),
        _t('Tác hại', tacHai, maxLines: 3),
        _t('Nhận biết (JSON list)', nhanBiet, maxLines: 3),
        _t('Biện pháp IPM (JSON object)', ipm, maxLines: 4),
        _t('Ảnh đại diện (URL)', photoUrl),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy ? null : _submitPest,
          icon: const Icon(Icons.save),
          label: const Text('Tạo Sâu'),
        ),
      ],
    );
  }

  Widget _buildDrugForm() {
    return ListView(
      children: [
        _t('Tên thuốc *', drugTen),
        _t('Hoạt chất', drugHoatChat),
        _t('Nhóm', drugNhom),
        _t('Hãng', drugHang),
        _t('Hướng dẫn', drugHuongDan, maxLines: 3),
        _t('Ghi chú', drugGhiChu, maxLines: 2),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy ? null : _submitDrug,
          icon: const Icon(Icons.medication),
          label: const Text('Tạo Thuốc'),
        ),
      ],
    );
  }

  Widget _buildLinkForm() {
    return ListView(
      children: [
        _t('Code sâu *', linkCode),
        _t('Drug Id *', linkDrugId),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: busy ? null : _submitLink,
          icon: const Icon(Icons.link),
          label: const Text('Gán Thuốc cho Sâu'),
        ),
      ],
    );
  }

  Widget _t(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
