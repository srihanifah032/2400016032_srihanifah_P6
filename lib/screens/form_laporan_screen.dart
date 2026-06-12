import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/database_helper.dart';
import '../models/laporan.dart';
import '../services/location_service.dart';
import 'riwayat_laporan_screen.dart';

const kRed = Color(0xFFC41C1C);
const kRedDark = Color(0xFF7F1D1D);
const kBg = Color(0xFFF4F4F5);

class FormLaporanScreen extends StatefulWidget {
  const FormLaporanScreen({super.key});

  @override
  State<FormLaporanScreen> createState() => _FormLaporanScreenState();
}

class _FormLaporanScreenState extends State<FormLaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _deskCtrl = TextEditingController();

  File? _imageFile;
  Position? _position;

  bool _loadingGps = false;
  bool _submitting = false;

  final _picker = ImagePicker();
  final _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();

    // GPS tidak otomatis diambil saat halaman dibuka.
    // User harus klik tombol "Ambil koordinat GPS".
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskCtrl.dispose();
    super.dispose();
  }

  Future<void> _ambilFoto(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (xfile != null) {
        setState(() {
          _imageFile = File(xfile.path);
        });

        _snack('Foto berhasil diambil!', ok: true);
      }
    } catch (e) {
      _snack('Gagal akses kamera: $e');
    }
  }

  Future<void> _ambilLokasi() async {
    if (!mounted) return;

    setState(() {
      _loadingGps = true;
    });

    try {
      final Position? pos = await LocationService.getCurrentLocation();

      if (!mounted) return;

      if (pos == null) {
        setState(() {
          _loadingGps = false;
        });

        _snack(
          'GPS gagal didapatkan. Aktifkan lokasi HP dan izinkan akses lokasi aplikasi.',
        );
        return;
      }

      setState(() {
        _position = pos;
        _loadingGps = false;
      });

      _snack('Lokasi berhasil diambil', ok: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingGps = false;
      });

      _snack('Error GPS: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      _snack('Harap ambil foto.');
      return;
    }

    if (_position == null) {
      _snack('Harap ambil koordinat GPS.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _db.insertLaporan(
        Laporan(
          judul: _judulCtrl.text.trim(),
          deskripsi: _deskCtrl.text.trim(),
          latitude: _position!.latitude,
          longitude: _position!.longitude,
          fotoPath: _imageFile!.path,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      _judulCtrl.clear();
      _deskCtrl.clear();

      setState(() {
        _imageFile = null;
        _position = null;
      });

      _snack('Laporan tersimpan!', ok: true);
    } catch (e) {
      _snack('Gagal simpan: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _submitting = false;
      });
    }
  }

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _buildHero(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFotoBlock(),
                    const SizedBox(height: 10),
                    _buildGpsBlock(),
                    const SizedBox(height: 10),
                    _buildDetailBlock(),
                    const SizedBox(height: 16),
                    _buildSubmitBtn(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: kRed,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAPORAN BARU',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade200,
                        fontWeight: FontWeight.w500,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pelaporan\nLapangan',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProgressChip(
                icon: Icons.location_on_outlined,
                label: 'GPS',
                done: _position != null,
              ),
              const SizedBox(width: 6),
              _ProgressChip(
                icon: Icons.camera_alt_outlined,
                label: 'Foto',
                done: _imageFile != null,
              ),
              const SizedBox(width: 6),
              _ProgressChip(
                icon: Icons.edit_outlined,
                label: 'Isi form',
                done: _judulCtrl.text.isNotEmpty,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RiwayatLaporanScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 13,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Riwayat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFotoBlock() {
    return _Block(
      icon: Icons.camera_alt_outlined,
      title: 'Bukti foto',
      badge: 'Wajib',
      badgeColor: const Color(0xFFFEE2E2),
      badgeTextColor: const Color(0xFF991B1B),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 32,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Belum ada foto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade300,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'Kamera',
                  icon: Icons.camera_alt_outlined,
                  color: kRed,
                  onTap: () => _ambilFoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Galeri',
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFF1A1A1A),
                  onTap: () => _ambilFoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGpsBlock() {
    final locked = _position != null;

    return _Block(
      icon: Icons.location_on_outlined,
      title: 'Lokasi GPS',
      badge: locked ? 'Terkunci' : 'Belum diambil',
      badgeColor: locked ? const Color(0xFFDCFCE7) : const Color(0xFFF4F4F5),
      badgeTextColor: locked ? const Color(0xFF15803D) : const Color(0xFF9CA3AF),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: locked ? const Color(0xFFF0FDF4) : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: locked ? Colors.green.shade200 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: locked ? const Color(0xFF22C55E) : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: locked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_position!.latitude.toStringAsFixed(6)}, '
                              '${_position!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Akurasi ±${_position!.accuracy.toStringAsFixed(1)}m',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Koordinat belum diambil',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ActionBtn(
            label: _loadingGps
                ? 'Mengambil lokasi...'
                : locked
                    ? 'Perbarui koordinat GPS'
                    : 'Ambil koordinat GPS',
            icon: Icons.my_location,
            color: locked ? Colors.green.shade700 : kRed,
            onTap: _loadingGps ? null : _ambilLokasi,
            loading: _loadingGps,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBlock() {
    return _Block(
      icon: Icons.edit_outlined,
      title: 'Detail kejadian',
      child: Column(
        children: [
          _FancyField(
            label: 'Judul laporan',
            controller: _judulCtrl,
            hint: 'Contoh: Jalan berlubang',
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Judul tidak boleh kosong';
              }
              if (v.trim().length < 5) {
                return 'Minimal 5 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          _FancyField(
            label: 'Deskripsi kejadian',
            controller: _deskCtrl,
            hint: 'Jelaskan kejadian secara detail...',
            maxLines: 4,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Deskripsi tidak boleh kosong';
              }
              if (v.trim().length < 10) {
                return 'Minimal 10 karakter';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBtn() {
    return GestureDetector(
      onTap: _submitting ? null : _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _submitting ? Colors.grey.shade400 : kRedDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_submitting)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            const SizedBox(width: 8),
            Text(
              _submitting ? 'Menyimpan...' : 'Kirim laporan',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;

  const _ProgressChip({
    required this.icon,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: done ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Widget child;

  const _Block({
    required this.icon,
    required this.title,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: kRed,
                ),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.grey.shade100,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final bool fullWidth;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade300 : color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FancyField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _FancyField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        validator: validator,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF374151),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9CA3AF),
          ),
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFFD1D5DB),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}