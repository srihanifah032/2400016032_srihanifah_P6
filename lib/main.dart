import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/form_laporan_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PelaporanApp());
}

class PelaporanApp extends StatelessWidget {
  const PelaporanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelaporan Lapangan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC41C1C),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F4F5),
        fontFamily: 'sans-serif',
      ),
      home: const FormLaporanScreen(),
    );
  }
}