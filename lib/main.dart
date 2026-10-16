import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pwWidgets;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excelPkg;
import 'package:file_picker/file_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

// دالة موحدة لتوليد تاريخ اليوم بالصيغة الجزائرية DD/MM/YYYY
String todayStr() {
  final now = DateTime.now();
  final d = now.day.toString().padLeft(2, '0');
  final m = now.month.toString().padLeft(2, '0');
  return '$d/$m/${now.year}';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SchoolData.loadData();
  runApp(const EducationalRegisterApp());
}

// ============================================================================
// 1. نماذج البيانات المتقدمة (MODELS)
// ============================================================================

class BehaviorLog {
  final String description;
  final int pointsChange;
  final String time;
  final String? reason;
  final String date;

  BehaviorLog({
    required this.description,
    required this.pointsChange,
    required this.time,
    this.reason,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'pointsChange': pointsChange,
        'time': time,
        'reason': reason,
        'date': date,
      };

  factory BehaviorLog.fromJson(Map<String, dynamic> json) => BehaviorLog(
        description: json['description'] ?? '',
        pointsChange: json['pointsChange'] ?? 0,
        time: json['time'] ?? '',
        reason: json['reason'],
        date: json['date'] ?? todayStr(),
      );
}

class LessonNote {
  String date;
  String title;
  String summary;
  String homework;

  LessonNote({
    required this.date,
    required this.title,
    required this.summary,
    required this.homework,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'title': title,
        'summary': summary,
        'homework': homework,
      };

  factory LessonNote.fromJson(Map<String, dynamic> json) => LessonNote(
        date: json['date'] ?? todayStr(),
        title: json['title'] ?? '',
        summary: json['summary'] ?? '',
        homework: json['homework'] ?? '',
      );
}

class DailyAttendanceRecord {
  String date;
  Map<String, String> studentStatuses; // المفتاح: رقم التعريف المدرسي regNumber

  DailyAttendanceRecord({
    required this.date,
    required this.studentStatuses,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'studentStatuses': studentStatuses,
      };

  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) => DailyAttendanceRecord(
        date: json['date'] ?? todayStr(),
        studentStatuses: json['studentStatuses'] != null
            ? Map<String, String>.from(json['studentStatuses'])
            : {},
      );
}

class TimetableItem {
  String day;
  String timeSlot;
  String className;
  String room;

  TimetableItem({
    required this.day,
    required this.timeSlot,
    required this.className,
    required this.room,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'timeSlot': timeSlot,
        'className': className,
        'room': room,
      };

  factory TimetableItem.fromJson(Map<String, dynamic> json) => TimetableItem(
        day: json['day'] ?? 'الأحد',
        timeSlot: json['timeSlot'] ?? '08:00 - 09:00',
        className: json['className'] ?? '',
        room: json['room'] ?? '',
      );
}

class Student {
  String firstName;
  String lastName;
  String regNumber; // رقم التعريف المدرسي (منصة رقمنة)
  String birthDate;
  String birthPlace;
  String status; // حاضر، غائب، مبرر
  double continuousEval; // التقويم المستمر والمشاركة
  double exam1;          // الفرض 1
  double exam2;          // الفرض 2
  double test;           // الاختبار الفصلي
  double coefficient;    // المعامل
  int points;            // نقاط السلوك / المواظبة (+ أو -)
  List<BehaviorLog> logs;

  Student({
    required this.firstName,
    required this.lastName,
    required this.regNumber,
    required this.birthDate,
    required this.birthPlace,
    this.status = 'حاضر',
    this.continuousEval = 10.0,
    this.exam1 = 10.0,
    this.exam2 = 10.0,
    this.test = 10.0,
    this.coefficient = 1.0,
    this.points = 0,
    List<BehaviorLog>? logs,
  }) : logs = logs ?? [];

  /// حساب معدل المادة وفق المنهاج التربوي الرسمي الجزائري
  double get average {
    double averageContinuousAndExams = (continuousEval + exam1 + exam2) / 3.0;
    return (averageContinuousAndExams + (test * 2.0)) / 3.0;
  }

  /// التقدير التربوي الرسمي
  String get appreciation {
    final avg = average;
    if (avg >= 18.0) return 'ممتاز';
    if (avg >= 16.0) return 'جيد جداً';
    if (avg >= 14.0) return 'جيد';
    if (avg >= 12.0) return 'قريب من الجيد';
    if (avg >= 10.0) return 'متوسط';
    if (avg >= 8.0) return 'دون المتوسط';
    return 'ضعيف';
  }

  /// قرار مجلس الأقسام الشرفي
  String get councilDecision {
    final avg = average;
    if (avg >= 16.0) return 'تهنئة + لوحة شرف';
    if (avg >= 14.0) return 'تشجيع + لوحة شرف';
    if (avg >= 12.0) return 'لوحة شرف';
    if (avg >= 10.0) return 'ينتقل';
    if (avg >= 8.0) return 'إنذار بالمواظبة والعمل';
    return 'توبيخ وطلب لقاء ولي الأمر';
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'regNumber': regNumber,
        'birthDate': birthDate,
        'birthPlace': birthPlace,
        'status': status,
        'continuousEval': continuousEval,
        'exam1': exam1,
        'exam2': exam2,
        'test': test,
        'coefficient': coefficient,
        'points': points,
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        regNumber: json['regNumber'] ?? '',
        birthDate: json['birthDate'] ?? '',
        birthPlace: json['birthPlace'] ?? '',
        status: json['status'] ?? 'حاضر',
        continuousEval: (json['continuousEval'] ?? 10.0).toDouble(),
        exam1: (json['exam1'] ?? 10.0).toDouble(),
        exam2: (json['exam2'] ?? 10.0).toDouble(),
        test: (json['test'] ?? 10.0).toDouble(),
        coefficient: (json['coefficient'] ?? 1.0).toDouble(),
        points: json['points'] ?? 0,
        logs: json['logs'] != null
            ? (json['logs'] as List).map((l) => BehaviorLog.fromJson(l)).toList()
            : [],
      );
}

class SchoolClass {
  String name;
  List<Student> students;
  List<LessonNote> lessonNotes;
  List<DailyAttendanceRecord> dailyRecords;

  SchoolClass({
    required this.name,
    required this.students,
    List<LessonNote>? lessonNotes,
    List<DailyAttendanceRecord>? dailyRecords,
  })  : lessonNotes = lessonNotes ?? [],
        dailyRecords = dailyRecords ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'students': students.map((s) => s.toJson()).toList(),
        'lessonNotes': lessonNotes.map((l) => l.toJson()).toList(),
        'dailyRecords': dailyRecords.map((d) => d.toJson()).toList(),
      };

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        name: json['name'] ?? '',
        students: json['students'] != null
            ? (json['students'] as List).map((s) => Student.fromJson(s)).toList()
            : [],
        lessonNotes: json['lessonNotes'] != null
            ? (json['lessonNotes'] as List).map((l) => LessonNote.fromJson(l)).toList()
            : [],
        dailyRecords: json['dailyRecords'] != null
            ? (json['dailyRecords'] as List)
                .map((d) => DailyAttendanceRecord.fromJson(d))
                .toList()
            : [],
      );
}

class Teacher {
  String name;
  String subject;
  String? imagePath;
  List<SchoolClass> classes;
  List<TimetableItem> timetable;

  Teacher({
    required this.name,
    required this.subject,
    this.imagePath,
    List<SchoolClass>? classes,
    List<TimetableItem>? timetable,
  })  : classes = classes ?? [],
        timetable = timetable ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'subject': subject,
        'imagePath': imagePath,
        'classes': classes.map((c) => c.toJson()).toList(),
        'timetable': timetable.map((t) => t.toJson()).toList(),
      };

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        name: json['name'] ?? '',
        subject: json['subject'] ?? '',
        imagePath: imagePath,
        classes: json['classes'] != null
            ? (json['classes'] as List).map((c) => SchoolClass.fromJson(c)).toList()
            : [],
        timetable: json['timetable'] != null
            ? (json['timetable'] as List)
                .map((t) => TimetableItem.fromJson(t))
                .toList()
            : [],
      );
}

class Institution {
  String name;
  List<Teacher> teachers;

  Institution({required this.name, List<Teacher>? teachers}) : teachers = teachers ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'teachers': teachers.map((t) => t.toJson()).toList(),
      };

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
        name: json['name'] ?? '',
        teachers: json['teachers'] != null
            ? (json['teachers'] as List).map((t) => Teacher.fromJson(t)).toList()
            : [],
      );
}

// ============================================================================
// 2. إدارة التخزين وقراءة البيانات (STORAGE & SYSTEM HELPERS)
// ============================================================================

class SchoolData {
  static List<Institution> institutions = [];
  static String appPin = "1234";

  static Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'institutionsData', jsonEncode(institutions.map((i) => i.toJson()).toList()));
    await prefs.setString('appPin', appPin);
  }

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    appPin = prefs.getString('appPin') ?? "1234";
    String? dataStr = prefs.getString('institutionsData');
    if (dataStr != null) {
      try {
        List<dynamic> decoded = jsonDecode(dataStr);
        institutions = decoded.map((i) => Institution.fromJson(i)).toList();
      } catch (e) {
        debugPrint("Error loading data: $e");
        _initSampleData();
      }
    } else {
      _initSampleData();
    }
  }

  static void _initSampleData() {
    institutions = [
      Institution(
        name: 'ثانوية السكومي نوري - الجلفة',
        teachers: [
          Teacher(
            name: 'الأستاذ: عبد الرحمن',
            subject: 'الرياضيات',
            timetable: [
              TimetableItem(
                  day: 'الأحد', timeSlot: '08:00 - 10:00', className: '3 ثانوي رياضيات 1', room: 'قاعة 04'),
            ],
            classes: [
              SchoolClass(name: '3 ثانوي رياضيات 1', students: [
                Student(
                    firstName: 'أحمد',
                    lastName: 'بن علي',
                    regNumber: '2026101',
                    birthDate: '15/05/2007',
                    birthPlace: 'الجلفة',
                    continuousEval: 17.5,
                    exam1: 16.0,
                    exam2: 17.0,
                    test: 18.0,
                    points: 5),
                Student(
                    firstName: 'فاطمة الزهراء',
                    lastName: 'قاسمي',
                    regNumber: '2026102',
                    birthDate: '22/08/2007',
                    birthPlace: 'الجلفة',
                    continuousEval: 18.5,
                    exam1: 17.5,
                    exam2: 19.0,
                    test: 18.5,
                    points: 8),
                Student(
                    firstName: 'يوسف',
                    lastName: 'براهيمي',
                    regNumber: '2026103',
                    birthDate: '10/02/2007',
                    birthPlace: 'الجلفة',
                    continuousEval: 12.0,
                    exam1: 11.5,
                    exam2: 10.0,
                    test: 11.0,
                    points: 2),
                Student(
                    firstName: 'سارة',
                    lastName: 'محدادي',
                    regNumber: '2026104',
                    birthDate: '03/11/2007',
                    birthPlace: 'الجلفة',
                    continuousEval: 09.0,
                    exam1: 08.5,
                    exam2: 07.5,
                    test: 08.0,
                    points: -3),
              ])
            ],
          )
        ],
      )
    ];
  }

  static String exportBackupJson() =>
      jsonEncode(institutions.map((i) => i.toJson()).toList());

  static Future<bool> importBackupJson(String jsonString) async {
    try {
      List<dynamic> decoded = jsonDecode(jsonString);
      institutions = decoded.map((i) => Institution.fromJson(i)).toList();
      await saveData();
      return true;
    } catch (e) {
      return false;
    }
  }
}

int compareArabicNames(String a, String b) {
  String normalize(String str) {
    return str
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll(RegExp(r'ة'), 'ه')
        .replaceAll(RegExp(r'ى'), 'ي')
        .trim();
  }
  return normalize(a).compareTo(normalize(b));
}

double? parseGrade(String val) {
  String cleaned = val.trim().replaceAll(',', '.');
  double? parsed = double.tryParse(cleaned);
  if (parsed != null && parsed >= 0.0 && parsed <= 20.0) {
    return parsed;
  }
  return null;
}

String extractCellString(dynamic cell) {
  if (cell == null || cell.value == null) return '';
  final val = cell.value;
  if (val is excelPkg.TextCellValue) return val.value.text?.trim() ?? '';
  if (val is excelPkg.IntCellValue) return val.value.toString().trim();
  if (val is excelPkg.DoubleCellValue) return val.value.toString().trim();
  return val.toString().trim();
}

// ============================================================================
// 3. جذر التطبيق والثيم التنفيذي الفاخر (EXECUTIVE LUXURY THEME)
// ============================================================================

class EducationalRegisterApp extends StatefulWidget {
  const EducationalRegisterApp({super.key});

  @override
  State<EducationalRegisterApp> createState() => _EducationalRegisterAppState();
}

class _EducationalRegisterAppState extends State<EducationalRegisterApp> {
  bool _isDarkMode = false;
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    SchoolData.loadData().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _unlockApp() {
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // الألوان التنفيذية الفاخرة: كحلي ملكي عميق، أخضر زمردي، وذهبي شرفي
    const deepNavy = Color(0xFF0F172A);
    const slateNavy = Color(0xFF1E293B);
    const emeraldAccent = Color(0xFF059669);
    const royalGold = Color(0xFFD97706);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'السجل التربوي التنفيذي 2026',
      locale: const Locale('ar', 'DZ'),
      supportedLocales: const [
        Locale('ar', 'DZ'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.light(
          primary: deepNavy,
          secondary: emeraldAccent,
          tertiary: royalGold,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: deepNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          tertiary: Color(0xFFF59E0B),
          surface: slateNavy,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B132B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: slateNavy,
        ),
      ),
      home: _isLocked
          ? PinLockScreen(onUnlock: _unlockApp)
          : InstitutionsListScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

// ============================================================================
// 4. شاشة الحماية الملكية (PIN & BIOMETRIC AUTH)
// ============================================================================

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  const PinLockScreen({super.key, required this.onUnlock});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  String errorMessage = "";
  int attempts = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometricsAutomatically();
  }

  Future<void> _checkBiometricsAutomatically() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canCheck) {
        bool authenticated = await _auth.authenticate(
          localizedReason: 'المصادقة البيومترية الآمنة لفتح السجل التربوي 2026',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        if (authenticated) {
          widget.onUnlock();
        }
      }
    } catch (e) {
      debugPrint("Biometric check skipped: $e");
    }
  }

  void _verifyPin() {
    if (_pinController.text == SchoolData.appPin) {
      widget.onUnlock();
    } else {
      setState(() {
        attempts++;
        errorMessage = "رمز المرور غير صحيح! (المحاولات: $attempts)";
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B132B), Color(0xFF1C2541), Color(0xFF047857)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 16,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, size: 48, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(height: 16),
                    const Text('السجل التربوي التنفيذي Pro',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('نظام الإدارة المدرسية المعتمد والمحمي',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        counterText: "",
                        hintText: "••••",
                      ),
                      onSubmitted: (_) => _verifyPin(),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: _verifyPin,
                        child: const Text('دخول النظام',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _checkBiometricsAutomatically,
                      icon: const Icon(Icons.fingerprint, color: Color(0xFF059669)),
                      label: const Text('فتح بالبصمة البيومترية',
                          style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. شاشة المؤسسات والمظهر الفاخر (INSTITUTIONS SCREEN)
// ============================================================================

class InstitutionsListScreen extends StatefulWidget {
  const InstitutionsListScreen(
      {super.key, required this.onThemeToggle, required this.isDarkMode});
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  @override
  State<InstitutionsListScreen> createState() => _InstitutionsListScreenState();
}

class _InstitutionsListScreenState extends State<InstitutionsListScreen> {
  void _showInstitutionDialog({Institution? institution}) {
    final nameCtrl = TextEditingController(text: institution?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(institution == null ? 'إضافة مؤسسة تربوية' : 'تعديل اسم المؤسسة'),
        content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'اسم المؤسسة والولاية')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  if (institution == null) {
                    SchoolData.institutions.add(Institution(name: nameCtrl.text.trim()));
                  } else {
                    institution.name = nameCtrl.text.trim();
                  }
                });
                await SchoolData.saveData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteInstitution(Institution institution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المؤسسة'),
        content: Text('هل أنت متأكد من حذف مؤسسة "${institution.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() {
                SchoolData.institutions.remove(institution);
              });
              await SchoolData.saveData();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السجل التربوي التنفيذي Pro 2026', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onThemeToggle),
        ],
      ),
      body: SchoolData.institutions.isEmpty
          ? const Center(child: Text('لا توجد مؤسسات تعليمية مسجلة بعد.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: SchoolData.institutions.length,
              itemBuilder: (context, index) {
                final inst = SchoolData.institutions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFFF59E0B)),
                    ),
                    title: Text(inst.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text('عدد الأساتذة: ${inst.teachers.length}', style: const TextStyle(color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => _showInstitutionDialog(institution: inst)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteInstitution(inst)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TeachersListScreen(
                                  institution: inst,
                                  onThemeToggle: widget.onThemeToggle,
                                  isDarkMode: widget.isDarkMode))).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF59E0B),
        onPressed: () => _showInstitutionDialog(),
        icon: const Icon(Icons.add_business),
        label: const Text('إضافة مؤسسة'),
      ),
    );
  }
}

// ============================================================================
// 6. شاشة الأساتذة (TEACHERS SCREEN)
// ============================================================================

class TeachersListScreen extends StatefulWidget {
  final Institution institution;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const TeachersListScreen(
      {super.key,
      required this.institution,
      required this.onThemeToggle,
      required this.isDarkMode});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  void _showTeacherDialog({Teacher? teacher}) {
    final nameCtrl = TextEditingController(text: teacher?.name ?? '');
    final subjectCtrl = TextEditingController(text: teacher?.subject ?? '');
    String? tempImagePath = teacher?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(teacher == null ? 'إضافة أستاذ جديد' : 'تعديل بيانات الأستاذ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setDialogState(() {
                          tempImagePath = pickedFile.path;
                        });
                      }
                    } catch (e) {
                      debugPrint("Image picker error: $e");
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        tempImagePath != null ? FileImage(File(tempImagePath!)) : null,
                    child: tempImagePath == null
                        ? const Icon(Icons.camera_alt, size: 28, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الأستاذ')),
                const SizedBox(height: 10),
                TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'المادة التعليمية')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && subjectCtrl.text.isNotEmpty) {
                  setState(() {
                    if (teacher == null) {
                      widget.institution.teachers.add(Teacher(
                          name: nameCtrl.text.trim(),
                          subject: subjectCtrl.text.trim(),
                          imagePath: tempImagePath));
                    } else {
                      teacher.name = nameCtrl.text.trim();
                      teacher.subject = subjectCtrl.text.trim();
                      teacher.imagePath = tempImagePath;
                    }
                  });
                  await SchoolData.saveData();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.institution.name),
      ),
      body: widget.institution.teachers.isEmpty
          ? const Center(child: Text('لا يوجد أساتذة مسجلون في هذه المؤسسة.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.institution.teachers.length,
              itemBuilder: (context, index) {
                final teacher = widget.institution.teachers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF059669),
                      backgroundImage: teacher.imagePath != null
                          ? FileImage(File(teacher.imagePath!))
                          : null,
                      child: teacher.imagePath == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(teacher.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text('المادة: ${teacher.subject} | عدد الأفواج: ${teacher.classes.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey),
                            onPressed: () => _showTeacherDialog(teacher: teacher)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ClassesScreen(
                                  institution: widget.institution, teacher: teacher))).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        onPressed: () => _showTeacherDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة أستاذ'),
      ),
    );
  }
}

// ============================================================================
// 7. شاشة الأقسام والجدول وتصدير التقارير (CLASSES SCREEN)
// ============================================================================

class ClassesScreen extends StatefulWidget {
  final Institution institution;
  final Teacher teacher;
  const ClassesScreen({super.key, required this.institution, required this.teacher});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  void _showClassDialog({SchoolClass? schoolClass}) {
    final classCtrl = TextEditingController(text: schoolClass?.name ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(schoolClass == null ? 'إضافة فوج تربوي' : 'تعديل اسم الفوج'),
        content: TextField(
            controller: classCtrl,
            decoration: const InputDecoration(hintText: 'مثال: 3 ثانوي علوم تجريبية 1')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () async {
              if (classCtrl.text.trim().isNotEmpty) {
                setState(() {
                  if (schoolClass == null) {
                    widget.teacher.classes.add(SchoolClass(name: classCtrl.text.trim(), students: []));
                  } else {
                    schoolClass.name = classCtrl.text.trim();
                  }
                });
                await SchoolData.saveData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// تصدير ملف Excel متوافق تماماً مع بنية منصة رقمنة الجزائرية
  Future<void> _exportRaqmanaExcel() async {
    try {
      var excel = excelPkg.Excel.createExcel();
      excelPkg.Sheet sheet = excel['كشف النقاط - رقمنة'];

      sheet.appendRow([
        excelPkg.TextCellValue('الجمهورية الجزائرية الديمقراطية الشعبية - وزارة التربية الوطنية'),
      ]);
      sheet.appendRow([
        excelPkg.TextCellValue('المؤسسة: ${widget.institution.name}'),
        excelPkg.TextCellValue('الأستاذ: ${widget.teacher.name}'),
        excelPkg.TextCellValue('المادة: ${widget.teacher.subject}'),
        excelPkg.TextCellValue('تاريخ التصدير: ${todayStr()}'),
      ]);
      sheet.appendRow([]); // سطر فارغ

      for (var c in widget.teacher.classes) {
        sheet.appendRow([excelPkg.TextCellValue('القسم: ${c.name}')]);
        // أعمدة مطابقة رسمية لمنصة رقمنة
        sheet.appendRow([
          excelPkg.TextCellValue('الرقم'),
          excelPkg.TextCellValue('رقم التعريف المدرسي'),
          excelPkg.TextCellValue('اللقب'),
          excelPkg.TextCellValue('الاسم'),
          excelPkg.TextCellValue('تاريخ الميلاد'),
          excelPkg.TextCellValue('التقويم المستمر'),
          excelPkg.TextCellValue('الفرض 1'),
          excelPkg.TextCellValue('الفرض 2'),
          excelPkg.TextCellValue('الاختبار'),
          excelPkg.TextCellValue('المعدل الفصلي'),
          excelPkg.TextCellValue('التقدير'),
        ]);

        for (int i = 0; i < c.students.length; i++) {
          var s = c.students[i];
          sheet.appendRow([
            excelPkg.IntCellValue(i + 1),
            excelPkg.TextCellValue(s.regNumber),
            excelPkg.TextCellValue(s.lastName),
            excelPkg.TextCellValue(s.firstName),
            excelPkg.TextCellValue(s.birthDate),
            excelPkg.DoubleCellValue(s.continuousEval),
            excelPkg.DoubleCellValue(s.exam1),
            excelPkg.DoubleCellValue(s.exam2),
            excelPkg.DoubleCellValue(s.test),
            excelPkg.DoubleCellValue(double.parse(s.average.toStringAsFixed(2))),
            excelPkg.TextCellValue(s.appreciation),
          ]);
        }
        sheet.appendRow([]);
      }

      Directory? directory = await getApplicationDocumentsDirectory();
      String path = '${directory.path}/Raqmana_Register_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      file.createSync(recursive: true);
      file.writeAsBytesSync(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تصدير ملف متوافق مع رقمنة بنجاح في:\n$path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء تصدير Excel: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents =
        widget.teacher.classes.fold(0, (sum, c) => sum + c.students.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacher.name} (${widget.teacher.subject})'),
        actions: [
          IconButton(
              icon: const Icon(Icons.table_view, color: Color(0xFFF59E0B)),
              tooltip: 'تصدير جدول متوافق مع رقمنة',
              onPressed: _exportRaqmanaExcel),
        ],
      ),
      body: Column(
        children: [
          // لوحة معلومات تنفيذية علوية
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  const Text('إجمالي الأفواج', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${widget.teacher.classes.length}',
                      style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 24,
                          fontWeight: FontWeight.bold))
                ]),
                Container(height: 36, width: 1, color: Colors.white24),
                Column(children: [
                  const Text('إجمالي التلاميذ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('$totalStudents',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold))
                ]),
              ],
            ),
          ),
          Expanded(
            child: widget.teacher.classes.isEmpty
                ? const Center(child: Text('لا توجد أقسام مسجلة بعد.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.teacher.classes.length,
                    itemBuilder: (context, index) {
                      final schoolClass = widget.teacher.classes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school, color: Color(0xFF0F172A)),
                          ),
                          title: Text(schoolClass.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          subtitle: Text('عدد التلاميذ: ${schoolClass.students.length}', style: const TextStyle(color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  onPressed: () =>
                                      _showClassDialog(schoolClass: schoolClass)),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ClassDashboardScreen(
                                        institution: widget.institution,
                                        teacher: widget.teacher,
                                        schoolClass: schoolClass))).then((_) => setState(() {}));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF59E0B),
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة قسم'),
      ),
    );
  }
}

// ============================================================================
// 8. لوحة تحكم القسم (الرسوم البيانية، كشوف النقاط الفردية مع QR، رقمنة)
// ============================================================================

class ClassDashboardScreen extends StatefulWidget {
  final Institution institution;
  final Teacher teacher;
  final SchoolClass schoolClass;

  const ClassDashboardScreen({
    super.key,
    required this.institution,
    required this.teacher,
    required this.schoolClass,
  });

  @override
  State<ClassDashboardScreen> createState() => _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends State<ClassDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  /// استيراد قائمة التلاميذ الذكية من ملف Excel متوافق مع صيغ رقمنة
  Future<void> _importStudentsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        Uint8List? bytes = result.files.single.bytes;
        if (bytes == null && result.files.single.path != null) {
          bytes = await File(result.files.single.path!).readAsBytes();
        }

        if (bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذر قراءة ملف Excel.')));
          }
          return;
        }

        var excel = excelPkg.Excel.decodeBytes(bytes);
        int addedCount = 0;

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          if (rows.isEmpty) continue;

          int startIndex = 0;
          if (rows.isNotEmpty) {
            String firstCell = extractCellString(rows[0][0]);
            if (firstCell.contains('اللقب') || firstCell.contains('Nom') || firstCell.contains('الرقم')) {
              startIndex = 1;
            }
          }

          for (int i = startIndex; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty) continue;

            String col0 = row.isNotEmpty ? extractCellString(row[0]) : '';
            String col1 = row.length > 1 ? extractCellString(row[1]) : '';
            String col2 = row.length > 2 ? extractCellString(row[2]) : '';
            String col3 = row.length > 3 ? extractCellString(row[3]) : '01/01/2007';
            String col4 = row.length > 4 ? extractCellString(row[4]) : 'الجلفة';

            String lastName = col0;
            String firstName = col1;
            String regNum = col2;

            // في جداول رقمنة الرسمية: العمود 0 رقم ترتيبي، العمود 1 رقم التعريف، العمود 2 اللقب، العمود 3 الاسم
            if (int.tryParse(col0) != null && row.length >= 4) {
              regNum = col1;
              lastName = col2;
              firstName = col3;
              col3 = row.length > 4 ? extractCellString(row[4]) : '01/01/2007';
            }

            if (lastName.isNotEmpty || firstName.isNotEmpty) {
              if (regNum.isEmpty) {
                regNum = '2026${widget.schoolClass.students.length + addedCount + 1}';
              }
              widget.schoolClass.students.add(Student(
                lastName: lastName,
                firstName: firstName,
                regNumber: regNum,
                birthDate: col3.isEmpty ? '01/01/2007' : col3,
                birthPlace: col4.isEmpty ? 'الجلفة' : col4,
              ));
              addedCount++;
            }
          }
        }

        await SchoolData.saveData();
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم استيراد $addedCount تلميذاً بنجاح من ملف رقمنة/Excel!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل استيراد Excel: $e')));
      }
    }
  }

  /// توليد كشف نقاط فردي رسمي مطبوع باللغة العربية مع رمز QR والختم الرقمي
  Future<void> _exportStudentBulletinPdf(Student student, int rank) async {
    try {
      final pdf = pwWidgets.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      final verificationData = jsonEncode({
        "school": widget.institution.name,
        "student": "${student.lastName} ${student.firstName}",
        "reg": student.regNumber,
        "class": widget.schoolClass.name,
        "avg": student.average.toStringAsFixed(2),
        "rank": "$rank / ${widget.schoolClass.students.length}",
        "decision": student.councilDecision,
        "date": todayStr(),
      });

      pdf.addPage(
        pwWidgets.Page(
          pageFormat: pw.PdfPageFormat.a4,
          textDirection: pwWidgets.TextDirection.rtl,
          theme: pwWidgets.ThemeData.withFont(base: arabicFont, bold: arabicBold),
          build: (pwWidgets.Context context) {
            return pwWidgets.Container(
              padding: const pwWidgets.EdgeInsets.all(24),
              decoration: pwWidgets.BoxDecoration(
                border: pwWidgets.Border.all(color: pw.PdfColors.blueGrey800, width: 2),
              ),
              child: pwWidgets.Column(
                crossAxisAlignment: pwWidgets.CrossAxisAlignment.stretch,
                children: [
                  // الترويسة الرسمية
                  pwWidgets.Center(
                    child: pwWidgets.Text('الجمهورية الجزائرية الديمقراطية الشعبية',
                        style: pwWidgets.TextStyle(fontSize: 14, fontWeight: pwWidgets.FontWeight.bold)),
                  ),
                  pwWidgets.Center(
                    child: pwWidgets.Text('وزارة التربية الوطنية - مديرية التربية لولاية الجلفة',
                        style: pwWidgets.TextStyle(fontSize: 12)),
                  ),
                  pwWidgets.SizedBox(height: 6),
                  pwWidgets.Row(
                    mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                    children: [
                      pwWidgets.Text('المؤسسة: ${widget.institution.name}'),
                      pwWidgets.Text('السنة الدراسية: 2025 / 2026'),
                    ],
                  ),
                  pwWidgets.Divider(thickness: 1.5, color: pw.PdfColors.blueGrey700),
                  pwWidgets.SizedBox(height: 8),

                  // عنوان الكشف
                  pwWidgets.Center(
                    child: pwWidgets.Container(
                      padding: const pwWidgets.EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      decoration: pwWidgets.BoxDecoration(
                        color: pw.PdfColors.grey200,
                        borderRadius: const pwWidgets.BorderRadius.all(pwWidgets.Radius.circular(6)),
                      ),
                      child: pwWidgets.Text('كشف النقاط والتقويم الفصلي للمادة',
                          style: pwWidgets.TextStyle(fontSize: 16, fontWeight: pwWidgets.FontWeight.bold)),
                    ),
                  ),
                  pwWidgets.SizedBox(height: 14),

                  // بيانات التلميذ
                  pwWidgets.Container(
                    padding: const pwWidgets.EdgeInsets.all(10),
                    decoration: pwWidgets.BoxDecoration(
                      border: pwWidgets.Border.all(color: pw.PdfColors.grey400),
                    ),
                    child: pwWidgets.Column(
                      children: [
                        pwWidgets.Row(
                          mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                          children: [
                            pwWidgets.Text('اللقب والاسم: ${student.lastName} ${student.firstName}',
                                style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold, fontSize: 13)),
                            pwWidgets.Text('رقم التعريف المدرسي: ${student.regNumber}'),
                          ],
                        ),
                        pwWidgets.SizedBox(height: 6),
                        pwWidgets.Row(
                          mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                          children: [
                            pwWidgets.Text('تاريخ ومكان الازدياد: ${student.birthDate} بـ ${student.birthPlace}'),
                            pwWidgets.Text('القسم / الفوج: ${widget.schoolClass.name}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pwWidgets.SizedBox(height: 16),

                  // جدول تفصيل العلامات
                  pwWidgets.Table(
                    border: pwWidgets.TableBorder.all(color: pw.PdfColors.black, width: 1),
                    children: [
                      pwWidgets.TableRow(
                        decoration: const pwWidgets.BoxDecoration(color: pw.PdfColors.grey300),
                        children: [
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('المادة'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('التقويم المستمر'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الفرض 1'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الفرض 2'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الاختبار (×2)'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('المعدل الفصلي'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الرتبة'))),
                        ],
                      ),
                      pwWidgets.TableRow(
                        children: [
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text(widget.teacher.subject, style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.continuousEval} / 20'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.exam1} / 20'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.exam2} / 20'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.test} / 20'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.average.toStringAsFixed(2)} / 20', style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('$rank من ${widget.schoolClass.students.length}'))),
                        ],
                      ),
                    ],
                  ),
                  pwWidgets.SizedBox(height: 14),

                  // التقديرات وملاحظات الأستاذ
                  pwWidgets.Container(
                    padding: const pwWidgets.EdgeInsets.all(10),
                    decoration: pwWidgets.BoxDecoration(border: pwWidgets.Border.all(color: pw.PdfColors.grey400)),
                    child: pwWidgets.Row(
                      mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                      children: [
                        pwWidgets.Text('التقدير البيداغوجي العام: ${student.appreciation}',
                            style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)),
                        pwWidgets.Text('قرار وملاحظة مجلس الأقسام: ${student.councilDecision}',
                            style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold, color: pw.PdfColors.blueGrey900)),
                      ],
                    ),
                  ),

                  pwWidgets.Spacer(),

                  // أسفل الكشف: رمز QR وختم المؤسسة وتوقيع الأستاذ
                  pwWidgets.Row(
                    mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pwWidgets.CrossAxisAlignment.end,
                    children: [
                      // كود QR الذكي للتحقق ومنع التزوير
                      pwWidgets.Column(
                        children: [
                          pwWidgets.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: verificationData,
                            width: 75,
                            height: 75,
                          ),
                          pwWidgets.SizedBox(height: 4),
                          pwWidgets.Text('رمز التحقق الرقمي', style: const pwWidgets.TextStyle(fontSize: 8)),
                        ],
                      ),

                      // ختم رقمي للمؤسسة
                      pwWidgets.Container(
                        width: 90,
                        height: 90,
                        decoration: pwWidgets.BoxDecoration(
                          shape: pwWidgets.BoxShape.circle,
                          border: pwWidgets.Border.all(color: pw.PdfColors.blue900, width: 2),
                        ),
                        child: pwWidgets.Center(
                          child: pwWidgets.Text(
                            'المطابقة الإدارية\nختم المؤسسة\n★ رسمي ★',
                            textAlign: pwWidgets.TextAlign.center,
                            style: pwWidgets.TextStyle(fontSize: 8, color: pw.PdfColors.blue900, fontWeight: pwWidgets.FontWeight.bold),
                          ),
                        ),
                      ),

                      // توقيع الأستاذ
                      pwWidgets.Column(
                        crossAxisAlignment: pwWidgets.CrossAxisAlignment.center,
                        children: [
                          pwWidgets.Text('أستاذ المادة: ${widget.teacher.name}'),
                          pwWidgets.SizedBox(height: 35),
                          pwWidgets.Text('التوقيع والمصادقة', style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (pw.PdfPageFormat format) async => pdf.save(),
        name: 'كشف_نقاط_${student.lastName}_${student.firstName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء إنشاء كشف النقاط: $e')));
      }
    }
  }

  /// إرسال إشعار غياب أو استدعاء عبر رسالة نصية/واتساب لولي الأمر
  void _sendGuardianNotification(Student student) {
    String message = '''
السلام عليكم ورحمة الله وبركاته،
إلى ولي أمر التلميذ(ة): ${student.lastName} ${student.firstName} (القسم: ${widget.schoolClass.name})
نحيطكم علماً بأن التلميذ مسجل بحالة (${student.status}) في حصة ${widget.teacher.subject} بتاريخ: ${todayStr()}.
معدل المادة الحالي: ${student.average.toStringAsFixed(2)} / 20.
يرجى متابعة التلميذ والتواصل مع الإدارة في حال الغياب غير المبرر.
مع تحيات أستاذ المادة: ${widget.teacher.name}
المؤسسة: ${widget.institution.name}
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إشعار ولي الأمر الفوري'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('النص المنسق للمشاركة عبر WhatsApp أو الرسائل النصية SMS:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
            icon: const Icon(Icons.copy),
            label: const Text('نسخ الرسالة'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: message));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ نص الرسالة! يمكنك لصقها الآن في تطبيق WhatsApp أو الرسائل.')));
            },
          ),
        ],
      ),
    );
  }

  void _showEditStudentGradesDialog(Student student) {
    final continuousCtrl = TextEditingController(text: student.continuousEval.toString());
    final exam1Ctrl = TextEditingController(text: student.exam1.toString());
    final exam2Ctrl = TextEditingController(text: student.exam2.toString());
    final testCtrl = TextEditingController(text: student.test.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('علامات التلميذ: ${student.lastName} ${student.firstName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: continuousCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'التقويم المستمر والمشاركة (0 - 20)'),
              ),
              TextField(
                controller: exam1Ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الفرض الأول (0 - 20)'),
              ),
              TextField(
                controller: exam2Ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الفرض الثاني (0 - 20)'),
              ),
              TextField(
                controller: testCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الاختبار الفصلي (0 - 20)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            onPressed: () async {
              double? c = parseGrade(continuousCtrl.text);
              double? e1 = parseGrade(exam1Ctrl.text);
              double? e2 = parseGrade(exam2Ctrl.text);
              double? t = parseGrade(testCtrl.text);

              if (c != null && e1 != null && e2 != null && t != null) {
                setState(() {
                  student.continuousEval = c;
                  student.exam1 = e1;
                  student.exam2 = e2;
                  student.test = t;
                });
                await SchoolData.saveData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث العلامات بدقة!')));
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال علامات صحيحة بين 0 و 20.')));
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widget.schoolClass.students.sort((a, b) => compareArabicNames(a.lastName, b.lastName));

    final filteredStudents = widget.schoolClass.students.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.lastName.toLowerCase().contains(q) ||
          s.firstName.toLowerCase().contains(q) ||
          s.regNumber.contains(q);
    }).toList();

    // حساب توزيع فئات المعدلات للرسم البياني
    int countWeak = widget.schoolClass.students.where((s) => s.average < 10.0).length;
    int countAverage = widget.schoolClass.students.where((s) => s.average >= 10.0 && s.average < 12.0).length;
    int countGood = widget.schoolClass.students.where((s) => s.average >= 12.0 && s.average < 14.0).length;
    int countVeryGood = widget.schoolClass.students.where((s) => s.average >= 14.0 && s.average < 16.0).length;
    int countExcellent = widget.schoolClass.students.where((s) => s.average >= 16.0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('قسم: ${widget.schoolClass.name}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFF59E0B),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'قائمة التلاميذ'),
            Tab(icon: Icon(Icons.bar_chart), text: 'مخطط الأداء البياني'),
            Tab(icon: Icon(Icons.menu_book), text: 'دفتر النصوص'),
            Tab(icon: Icon(Icons.event_available), text: 'سجل الحضور'),
            Tab(icon: Icon(Icons.upload_file), text: 'استيراد رقمنة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. تبويب قائمة التلاميذ وكشوف النقاط
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم، اللقب، أو رقم التعريف المدرسي...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0F172A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _studentSearchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(child: Text('لا يوجد تلاميذ مطابقون.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          // ترتيب التلميذ في القسم بحسب المعدل
                          List<Student> sortedByAvg = List.from(widget.schoolClass.students)
                            ..sort((a, b) => b.average.compareTo(a.average));
                          int rank = sortedByAvg.indexOf(student) + 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: student.average >= 10.0
                                    ? const Color(0xFF059669)
                                    : Colors.redAccent,
                                child: Text('$rank',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Row(
                                children: [
                                  Text('${student.lastName} ${student.firstName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  if (student.average >= 16.0)
                                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                                ],
                              ),
                              subtitle: Text(
                                  'المعدل: ${student.average.toStringAsFixed(2)}/20 (${student.appreciation}) | تقويم: ${student.continuousEval} | ف1: ${student.exam1} | اخت: ${student.test}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // زر استخراج كشف النقاط الفردي الرسمي مع كود QR
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD97706)),
                                    tooltip: 'كشف نقاط رسمي مع QR',
                                    onPressed: () => _exportStudentBulletinPdf(student, rank),
                                  ),
                                  // زر إرسال إشعار فوري لولي الأمر
                                  IconButton(
                                    icon: const Icon(Icons.notifications_active, color: Color(0xFF059669)),
                                    tooltip: 'إشعار فوري لولي الأمر',
                                    onPressed: () => _sendGuardianNotification(student),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                                    tooltip: 'تعديل العلامات',
                                    onPressed: () => _showEditStudentGradesDialog(student),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // 2. تبويب المخطط البياني التفاعلي لتوزيع المعدلات (fl_chart)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'منحنى توزيع المعدلات في الفوج (أعمدة بيانية)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (widget.schoolClass.students.length.toDouble() + 2),
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('< 10', style: TextStyle(fontSize: 11));
                                        case 1:
                                          return const Text('10-12', style: TextStyle(fontSize: 11));
                                        case 2:
                                          return const Text('12-14', style: TextStyle(fontSize: 11));
                                        case 3:
                                          return const Text('14-16', style: TextStyle(fontSize: 11));
                                        case 4:
                                          return const Text('16-20', style: TextStyle(fontSize: 11));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(toY: countWeak.toDouble(), color: Colors.redAccent, width: 22, borderRadius: BorderRadius.circular(6))
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(toY: countAverage.toDouble(), color: Colors.orange, width: 22, borderRadius: BorderRadius.circular(6))
                                ]),
                                BarChartGroupData(x: 2, barRods: [
                                  BarChartRodData(toY: countGood.toDouble(), color: Colors.blueGrey, width: 22, borderRadius: BorderRadius.circular(6))
                                ]),
                                BarChartGroupData(x: 3, barRods: [
                                  BarChartRodData(toY: countVeryGood.toDouble(), color: const Color(0xFF0D9488), width: 22, borderRadius: BorderRadius.circular(6))
                                ]),
                                BarChartGroupData(x: 4, barRods: [
                                  BarChartRodData(toY: countExcellent.toDouble(), color: const Color(0xFFF59E0B), width: 22, borderRadius: BorderRadius.circular(6))
                                ]),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('ضعيف: $countWeak', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('متوسط: $countAverage', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('حسن: $countGood', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('ممتاز: $countExcellent', style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.trending_up, color: Color(0xFF059669), size: 32),
                          title: const Text('نسبة النجاح العامة في الفوج'),
                          trailing: Text(
                            '${widget.schoolClass.students.isEmpty ? "0" : ((widget.schoolClass.students.where((s) => s.average >= 10.0).length / widget.schoolClass.students.length) * 100).toStringAsFixed(1)} %',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.calculate_outlined, color: Color(0xFF0F172A), size: 32),
                          title: const Text('المعدل العام للمادة'),
                          trailing: Text(
                            '${widget.schoolClass.students.isEmpty ? "0.00" : (widget.schoolClass.students.fold(0.0, (sum, s) => sum + s.average) / widget.schoolClass.students.length).toStringAsFixed(2)} / 20',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. دفتر النصوص
          widget.schoolClass.lessonNotes.isEmpty
              ? const Center(child: Text('لا توجد مذكرات دروس مسجلة بعد.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.schoolClass.lessonNotes.length,
                  itemBuilder: (context, index) {
                    final note = widget.schoolClass.lessonNotes[index];
                    return Card(
                      child: ListTile(
                        title: Text('${note.date}: ${note.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الخلاصة: ${note.summary}\nالعمل المنزلي: ${note.homework}'),
                      ),
                    );
                  },
                ),

          // 4. سجل الحضور
          widget.schoolClass.dailyRecords.isEmpty
              ? const Center(child: Text('لا توجد سجلات حضور مسجلة بعد.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.schoolClass.dailyRecords.length,
                  itemBuilder: (context, index) {
                    final record = widget.schoolClass.dailyRecords[index];
                    int present = record.studentStatuses.values.where((v) => v == 'حاضر').length;
                    int absent = record.studentStatuses.values.where((v) => v == 'غائب').length;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF059669), child: Icon(Icons.event, color: Colors.white)),
                        title: Text('تاريخ الحصة: ${record.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الحاضرون: $present | الغائبون: $absent'),
                      ),
                    );
                  },
                ),

          // 5. استيراد ملفات رقمنة
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 70, color: Color(0xFF059669)),
                  const SizedBox(height: 16),
                  const Text('استيراد قائمة التلاميذ من ملف منصة «رقمنة»',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'يتعرف النظام تلقائياً على أعمدة: رقم التعريف المدرسي، اللقب، الاسم، تاريخ ومكان الميلاد بصيغتي (.xlsx و .xls)',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('اختيار ملف من ذاكرة الهاتف', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _importStudentsFromExcel,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
