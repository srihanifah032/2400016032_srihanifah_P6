import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      // 1. Cek apakah layanan lokasi HP aktif
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        print("PENYEBAB: Layanan lokasi HP mati");
        await Geolocator.openLocationSettings();
        return null;
      }

      // 2. Cek izin lokasi aplikasi
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        print("PENYEBAB: Izin lokasi ditolak");
        return null;
      }

      if (permission == LocationPermission.deniedForever) {
        print("PENYEBAB: Izin lokasi ditolak permanen");
        await Geolocator.openAppSettings();
        return null;
      }

      // 3. Coba ambil lokasi terakhir dulu
      final Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        print("LOKASI TERAKHIR TERSEDIA");
        print("LAT LAST: ${lastPosition.latitude}");
        print("LNG LAST: ${lastPosition.longitude}");
      } else {
        print("Lokasi terakhir belum tersedia");
      }

      // 4. Ambil lokasi terbaru
      try {
        final Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 30),
        );

        print("LOKASI TERBARU BERHASIL");
        print("LAT: ${currentPosition.latitude}");
        print("LNG: ${currentPosition.longitude}");
        print("AKURASI: ${currentPosition.accuracy}");

        return currentPosition;
      } on TimeoutException {
        print("PENYEBAB: GPS timeout");

        // Kalau lokasi terbaru gagal, pakai lokasi terakhir
        if (lastPosition != null) {
          print("Menggunakan lokasi terakhir karena GPS timeout");
          return lastPosition;
        }

        return null;
      }
    } catch (e) {
      print("ERROR GPS: $e");
      return null;
    }
  }
}