import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:forui/forui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';
import 'components/app_gate.dart';
// import 'utils/upload_landmarks.dart';
// import 'utils/upload_reports.dart';
// import 'utils/upload_quests.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Disable Firestore cache for real-time updates
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: false,
  );
  
  // UPLOAD DATA (Run once, then comment out)
  // Uncomment untuk upload landmarks, reports, & quests ke Firestore
    // final landmarksUploader = UploadLandmarks();
    // await landmarksUploader.uploadToFirestore();
    // final reportsUploader = UploadReports();
    // await reportsUploader.uploadToFirestore();
    // final questsUploader = UploadQuests();
    // await questsUploader.uploadToFirestore();
    // print('✅ Data uploaded! Comment out this code now.');
    
  runApp(const SigapMedanApp());
}

class SigapMedanApp extends StatefulWidget {
  const SigapMedanApp({super.key});

  @override
  State<SigapMedanApp> createState() => _SigapMedanAppState();
}

class _SigapMedanAppState extends State<SigapMedanApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIGAP Medan',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return FTheme(
          data: brightness == Brightness.dark 
              ? FThemes.zinc.dark 
              : FThemes.zinc.light,
          child: child!,
        );
      },
      home: AppGate(
        child: AuthWrapper(
          currentTheme: _themeMode,
          onThemeChanged: _changeTheme,
        ),
      ),
    );
  }
}
