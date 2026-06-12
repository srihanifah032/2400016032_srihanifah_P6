import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/laporan.dart';

const kRed = Color(0xFFC41C1C);

class RiwayatLaporanScreen extends StatefulWidget {
  const RiwayatLaporanScreen({super.key});
  @override
  State<RiwayatLaporanScreen> createState() => _RiwayatLaporanScreenState();
}

class _RiwayatLaporanScreenState extends State<RiwayatLaporanScreen> {
  final _db = DatabaseHelper();
  late Future<List<Laporan>> _future;
  String _filter = 'Semua';

@override
void initState() {
  super.initState();
  _load();
}

void _load() {
  _future = _db.getAllLaporan();

  if (mounted) {
    setState(() {});
  }
}

  List<Laporan> _applyFilter(List<Laporan> list) {
    if (_filter == 'Semua') return list;
    final now = DateTime.now();
    return list.where((l) {
      final dt = DateTime.tryParse(l.createdAt);
      if (dt == null) return false;
      if (_filter == 'Hari ini') {
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      }
      if (_filter == 'Minggu ini') {
        return now.difference(dt).inDays < 7;
      }
      return true;
    }).toList();
  }

  Future<void> _hapus(int id, String judul) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus laporan?'),
        content: Text('"$judul" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) { await _db.deleteLaporan(id); _load(); }
  }

  Color _accentColor(int index) {
    final colors = [kRed, const Color(0xFFD97706), const Color(0xFF16A34A)];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: FutureBuilder<List<Laporan>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kRed));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final all  = snap.data ?? [];
                final list = _applyFilter(all);

                return Column(
                  children: [
                    _buildFilter(),
                    if (list.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.folder_open_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Tidak ada laporan',
                                style: TextStyle(color: Colors.grey.shade400)),
                          ]),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _buildItem(list[i], i),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return FutureBuilder<List<Laporan>>(
      future: _future,
      builder: (context, snap) {
        final list   = snap.data ?? [];
        final now    = DateTime.now();
        final hariIni = list.where((l) {
          final dt = DateTime.tryParse(l.createdAt);
          return dt != null && dt.year == now.year &&
              dt.month == now.month && dt.day == now.day;
        }).length;
        final kemarin = list.where((l) {
          final dt = DateTime.tryParse(l.createdAt);
          if (dt == null) return false;
          final diff = now.difference(dt).inDays;
          return diff == 1;
        }).length;

        return Container(
          color: const Color(0xFF0F0F0F),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16, right: 16, bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Riwayat laporan',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _load,
                    child: const Icon(Icons.refresh,
                        color: Color(0xFF666666), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatCard(value: '${list.length}', label: 'Total',
                      valueColor: const Color(0xFFF87171)),
                  const SizedBox(width: 8),
                  _StatCard(value: '$hariIni', label: 'Hari ini'),
                  const SizedBox(width: 8),
                  _StatCard(value: '$kemarin', label: 'Kemarin'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: ['Semua', 'Hari ini', 'Minggu ini'].map((f) {
          final active = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? kRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? kRed : Colors.grey.shade200),
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: active ? Colors.white : Colors.grey.shade500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem(Laporan item, int index) {
    final accent = _accentColor(index);
    String formatDate(String iso) {
      try {
        final dt = DateTime.parse(iso);
        return '${dt.day.toString().padLeft(2,'0')}/'
            '${dt.month.toString().padLeft(2,'0')}/'
            '${dt.year}  '
            '${dt.hour.toString().padLeft(2,'0')}:'
            '${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) { return iso; }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Accent bar kiri
          Container(
            width: 4, height: 80,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          const SizedBox(width: 10),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52, height: 52,
              child: item.fotoPath != null && File(item.fotoPath!).existsSync()
                  ? Image.file(File(item.fotoPath!), fit: BoxFit.cover)
                  : Container(
                      color: accent.withOpacity(0.1),
                      child: Icon(Icons.image_outlined,
                          color: accent.withOpacity(0.5))),
            ),
          ),
          const SizedBox(width: 10),
          // Konten
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${item.id}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                          color: accent)),
                  const SizedBox(height: 2),
                  Text(item.judul,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: Color(0xFF111111)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.deskripsi,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: Color(0xFF059669)),
                    const SizedBox(width: 2),
                    Text(
                      '${item.latitude.toStringAsFixed(4)}, '
                      '${item.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF059669)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_outlined,
                        size: 11, color: Color(0xFFD1D5DB)),
                    const SizedBox(width: 2),
                    Text(formatDate(item.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFD1D5DB))),
                  ]),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFFCA5A5), size: 18),
            onPressed: () => _hapus(item.id!, item.judul),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w500, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(
              fontSize: 10, color: Color(0xFF666666))),
        ]),
      ),
    );
  }
}
