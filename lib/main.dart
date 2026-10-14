import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

// นำำค่านี้มาจาก Firebase Console ตามข้อ 3.6
const String kServerClientId =
    '666619325899-m1gq24banamhoplj1lhih2finm3i8j2o.apps.googleusercontent.com'; //แก้ไขให้ตรงกับของตัวเอง
const Color _brandColor = Color(0xFF557C70);

Future<void> main() async {
  // เตรียมส่วนเชื่อมต่อกับระบบปฏิบัติการให้พร้อม
  // จำำเป็นเมื่อต้องเรียกโค้ดฝั่ง Native ก่อน runApp() จะทำำงาน
  WidgetsFlutterBinding.ensureInitialized();
  // เชื่อมต่อกับโปรเจกต์ Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // เตรียม GoogleSignIn ให้พร้อม ต้องทำำก่อนเรียก authenticate()
  await AuthService.init(kServerClientId);
  runApp(const MsuFoodApp());
}

class MsuFoodApp extends StatelessWidget {
  const MsuFoodApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSU Food',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: _brandColor,
          onPrimary: Colors.white,
          surface: const Color(0xFFFCFDFC),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F8F6),
          foregroundColor: Color(0xFF263A34),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE7ECE8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E9E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E9E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _brandColor, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? _brandColor.withValues(alpha: 0.38)
                  : _brandColor,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? Colors.black38
                  : Colors.white,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? _brandColor.withValues(alpha: 0.38)
                  : _brandColor,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? Colors.black38
                  : Colors.white,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? _brandColor.withValues(alpha: 0.38)
                  : _brandColor,
            ),
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.disabled)
                    ? _brandColor.withValues(alpha: 0.38)
                    : _brandColor,
              ),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? _brandColor.withValues(alpha: 0.38)
                  : _brandColor,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? _brandColor.withValues(alpha: 0.38)
                  : _brandColor,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
        ),
      ),
      // สามส่วนนี้ทำำให้กล่องโต้ตอบมาตรฐานแสดงเป็นภาษาไทย
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th'), Locale('en')],
      locale: const Locale('th'),
      home: const AuthGate(),
    );
  }
}
