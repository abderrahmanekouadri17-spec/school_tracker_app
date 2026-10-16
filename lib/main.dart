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
// 1. نماذج البيانات (MODELS)
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
  Map<String, String> studentStatuses;

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
  String regNumber;
  String birthDate;
  String birthPlace;
  String status;
  double continuousEval;
  double exam1;
  double exam2;
  double test;
  double coefficient;
  int points;
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

  double get average {
    double averageContinuousAndExams = (continuousEval + exam1 + exam2) / 3.0;
    return (averageContinuousAndExams + (test * 2.0)) / 3.0;
  }

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

  String get councilDecision {
    final avg = average;
    if (avg >= 16.0) return 'تهنئة + لوحة شرف';
    if (avg >= 14.0) return 'تشجيع + لوحة شرف';
    if (avg >= 12.0) return 'لوحة شرف';
    if (avg >= 10.0) return 'ينتقل';
    if (avg >= 8.0) return 'إنذار بالمواظبة';
    return 'توبيخ وطلب لقاء الولي';
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
// 2. إدارة التخزين (STORAGE)
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
                    test: 18.0),
                Student(
                    firstName: 'فاطمة الزهراء',
                    lastName: 'قاسمي',
                    regNumber: '2026102',
                    birthDate: '22/08/2007',
                    birthPlace: 'الجلفة',
                    continuousEval: 18.5,
                    exam1: 17.5,
                    exam2: 19.0,
                    test: 18.5),
              ])
            ],
          )
        ],
      )
    ];
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
  if (cell == null) return '';
  try {
    dynamic val = cell.value;
    if (val == null) return '';
    return val.toString().trim();
  } catch (_) {
    return cell.toString().trim();
  }
}

// ============================================================================
// 3. التطبيق والثيم التنفيذي (EXECUTIVE THEME)
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
    const deepNavy = Color(0xFF0F172A);
    const emeraldAccent = Color(0xFF059669);
    const royalGold = Color(0xFFD97706);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'السجل التربوي التنفيذي 2026',
      locale: const Locale('ar', 'DZ'),
      supportedLocales: const [Locale('ar', 'DZ'), Locale('ar')],
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
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: deepNavy,
          foregroundColor: Colors.white,
          elevation: 0,
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
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B132B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: _isLocked
          ? PinLockScreen(onUnlock: _unlockApp)
          : InstitutionsListScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

// ============================================================================
// 4. شاشة الحماية (PIN LOCK)
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

  void _verifyPin() {
    if (_pinController.text == SchoolData.appPin) {
      widget.onUnlock();
    } else {
      setState(() {
        errorMessage = "رمز المرور غير صحيح!";
        _pinController.clear();
      });
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      bool canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (canCheck) {
        bool authSuccess = await _auth.authenticate(
          localizedReason: 'المصادقة لفتح السجل التربوي 2026',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        if (authSuccess) {
          widget.onUnlock();
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B132B), Color(0xFF047857)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, size: 54, color: Color(0xFFD97706)),
                    const SizedBox(height: 16),
                    const Text('السجل التربوي التنفيذي Pro',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('أدخل رمز المرور الافتراضي (1234)',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        counterText: "",
                      ),
                      onSubmitted: (_) => _verifyPin(),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: _verifyPin,
                        child: const Text('دخول'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _checkBiometrics,
                      icon: const Icon(Icons.fingerprint, color: Color(0xFF059669)),
                      label: const Text('المصادقة بالبصمة'),
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
// 5. شاشة المؤسسات (INSTITUTIONS)
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
  void _showAddInstitutionDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مؤسسة جديدة'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المؤسسة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  SchoolData.institutions.add(Institution(name: nameCtrl.text.trim()));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المؤسسات التربوية 2026'),
        actions: [
          IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onThemeToggle),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: SchoolData.institutions.length,
        itemBuilder: (context, index) {
          final inst = SchoolData.institutions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0F172A),
                  child: Icon(Icons.school, color: Color(0xFFF59E0B))),
              title: Text(inst.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('الأساتذة: ${inst.teachers.length}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: const Color(0xFFF59E0B),
        onPressed: _showAddInstitutionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// 6. شاشة الأساتذة (TEACHERS)
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.institution.name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.institution.teachers.length,
        itemBuilder: (context, index) {
          final teacher = widget.institution.teachers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF059669),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('المادة: ${teacher.subject} | الأفواج: ${teacher.classes.length}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
    );
  }
}

// ============================================================================
// 7. شاشة الأقسام وتصدير كشف رقمنة Excel (CLASSES)
// ============================================================================

class ClassesScreen extends StatefulWidget {
  final Institution institution;
  final Teacher teacher;
  const ClassesScreen({super.key, required this.institution, required this.teacher});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  Future<void> _exportExcel() async {
    try {
      var excel = excelPkg.Excel.createExcel();
      excelPkg.Sheet sheet = excel['رقمنة'];

      sheet.appendRow([
        excelPkg.TextCellValue('المؤسسة: ${widget.institution.name}'),
        excelPkg.TextCellValue('الأستاذ: ${widget.teacher.name}'),
        excelPkg.TextCellValue('المادة: ${widget.teacher.subject}'),
        excelPkg.TextCellValue('التاريخ: ${todayStr()}'),
      ]);

      for (var c in widget.teacher.classes) {
        sheet.appendRow([excelPkg.TextCellValue('القسم: ${c.name}')]);
        sheet.appendRow([
          excelPkg.TextCellValue('الرقم'),
          excelPkg.TextCellValue('رقم التعريف'),
          excelPkg.TextCellValue('اللقب'),
          excelPkg.TextCellValue('الاسم'),
          excelPkg.TextCellValue('المعدل'),
          excelPkg.TextCellValue('التقدير'),
        ]);

        for (int i = 0; i < c.students.length; i++) {
          var s = c.students[i];
          sheet.appendRow([
            excelPkg.TextCellValue('${i + 1}'),
            excelPkg.TextCellValue(s.regNumber),
            excelPkg.TextCellValue(s.lastName),
            excelPkg.TextCellValue(s.firstName),
            excelPkg.TextCellValue(s.average.toStringAsFixed(2)),
            excelPkg.TextCellValue(s.appreciation),
          ]);
        }
      }

      Directory? dir = await getApplicationDocumentsDirectory();
      String path = '${dir.path}/Raqmana_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      file.createSync(recursive: true);
      file.writeAsBytesSync(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تصدير ملف Excel بنجاح في:\n$path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء التصدير: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacher.name} (${widget.teacher.subject})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart, color: Color(0xFFF59E0B)),
            tooltip: 'تصدير كشف رقمنة Excel',
            onPressed: _exportExcel,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.teacher.classes.length,
        itemBuilder: (context, index) {
          final c = widget.teacher.classes[index];
          return Card(
            child: ListTile(
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('عدد التلاميذ: ${c.students.length}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ClassDashboardScreen(
                            institution: widget.institution,
                            teacher: widget.teacher,
                            schoolClass: c))).then((_) => setState(() {}));
              },
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// 8. لوحة تحكم القسم (الرسم البياني وكشف النقاط الفردي الرسمي مع كود QR)
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

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

        if (bytes != null) {
          var excel = excelPkg.Excel.decodeBytes(bytes);
          int added = 0;

          for (var table in excel.tables.keys) {
            var rows = excel.tables[table]!.rows;
            int start = 0;
            if (rows.isNotEmpty) {
              String f = extractCellString(rows[0][0]);
              if (f.contains('اللقب') || f.contains('الرقم') || f.contains('Nom')) {
                start = 1;
              }
            }

            for (int i = start; i < rows.length; i++) {
              var r = rows[i];
              if (r.isEmpty) continue;
              String col0 = r.isNotEmpty ? extractCellString(r[0]) : '';
              String col1 = r.length > 1 ? extractCellString(r[1]) : '';
              String col2 = r.length > 2 ? extractCellString(r[2]) : '';
              String col3 = r.length > 3 ? extractCellString(r[3]) : '01/01/2007';

              String lastName = col0;
              String firstName = col1;
              String regNum = col2;

              if (int.tryParse(col0) != null && r.length >= 4) {
                regNum = col1;
                lastName = col2;
                firstName = col3;
              }

              if (lastName.isNotEmpty || firstName.isNotEmpty) {
                widget.schoolClass.students.add(Student(
                  lastName: lastName,
                  firstName: firstName,
                  regNumber: regNum.isEmpty ? '2026${widget.schoolClass.students.length + 1}' : regNum,
                  birthDate: '01/01/2007',
                  birthPlace: 'الجلفة',
                ));
                added++;
              }
            }
          }
          await SchoolData.saveData();
          setState(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم استيراد $added تلميذاً بنجاح!')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الاستيراد: $e')));
      }
    }
  }

  /// توليد كشف نقاط فردي رسمي مطبوع بـ PDF مع رمز QR وختم رقمي
  Future<void> _exportStudentBulletinPdf(Student student, int rank) async {
    try {
      final pdf = pwWidgets.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      final qrText = "المؤسسة: ${widget.institution.name}\nالتلميذ: ${student.lastName} ${student.firstName}\nالمعدل: ${student.average.toStringAsFixed(2)}\nالرتبة: $rank";

      pdf.addPage(
        pwWidgets.Page(
          pageFormat: pw.PdfPageFormat.a4,
          textDirection: pwWidgets.TextDirection.rtl,
          theme: pwWidgets.ThemeData.withFont(base: arabicFont, bold: arabicBold),
          build: (pwWidgets.Context context) {
            return pwWidgets.Container(
              padding: const pwWidgets.EdgeInsets.all(24),
              decoration: pwWidgets.BoxDecoration(
                border: pwWidgets.Border.all(color: pw.PdfColors.black, width: 2),
              ),
              child: pwWidgets.Column(
                crossAxisAlignment: pwWidgets.CrossAxisAlignment.stretch,
                children: [
                  pwWidgets.Center(
                    child: pwWidgets.Text('الجمهورية الجزائرية الديمقراطية الشعبية',
                        style: pwWidgets.TextStyle(fontSize: 14, fontWeight: pwWidgets.FontWeight.bold)),
                  ),
                  pwWidgets.Center(
                    child: pwWidgets.Text('وزارة التربية الوطنية - السجل البيداغوجي الشامل',
                        style: const pwWidgets.TextStyle(fontSize: 12)),
                  ),
                  pwWidgets.Divider(thickness: 1.5),
                  pwWidgets.SizedBox(height: 10),
                  pwWidgets.Row(
                    mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                    children: [
                      pwWidgets.Text('المؤسسة: ${widget.institution.name}'),
                      pwWidgets.Text('تاريخ الكشف: ${todayStr()}'),
                    ],
                  ),
                  pwWidgets.SizedBox(height: 16),
                  pwWidgets.Container(
                    padding: const pwWidgets.EdgeInsets.all(10),
                    decoration: pwWidgets.BoxDecoration(border: pwWidgets.Border.all(color: pw.PdfColors.grey400)),
                    child: pwWidgets.Row(
                      mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                      children: [
                        pwWidgets.Text('التلميذ: ${student.lastName} ${student.firstName}', style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)),
                        pwWidgets.Text('رقم التعريف: ${student.regNumber}'),
                        pwWidgets.Text('القسم: ${widget.schoolClass.name}'),
                      ],
                    ),
                  ),
                  pwWidgets.SizedBox(height: 20),
                  pwWidgets.Table(
                    border: pwWidgets.TableBorder.all(color: pw.PdfColors.black, width: 1),
                    children: [
                      pwWidgets.TableRow(
                        decoration: const pwWidgets.BoxDecoration(color: pw.PdfColors.grey300),
                        children: [
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('المادة'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('التقويم'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الفرض 1'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الاختبار'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('المعدل'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(6), child: pwWidgets.Center(child: pwWidgets.Text('الرتبة'))),
                        ],
                      ),
                      pwWidgets.TableRow(
                        children: [
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text(widget.teacher.subject))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.continuousEval}'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.exam1}'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('${student.test}'))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text(student.average.toStringAsFixed(2), style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)))),
                          pwWidgets.Padding(padding: const pwWidgets.EdgeInsets.all(8), child: pwWidgets.Center(child: pwWidgets.Text('$rank / ${widget.schoolClass.students.length}'))),
                        ],
                      ),
                    ],
                  ),
                  pwWidgets.SizedBox(height: 16),
                  pwWidgets.Text('ملاحظة وقرار مجلس الأقسام: ${student.councilDecision}', style: pwWidgets.TextStyle(fontWeight: pwWidgets.FontWeight.bold)),
                  pwWidgets.Spacer(),
                  pwWidgets.Row(
                    mainAxisAlignment: pwWidgets.MainAxisAlignment.spaceBetween,
                    children: [
                      pwWidgets.BarcodeWidget(
                        barcode: pwWidgets.Barcode.qrCode(),
                        data: qrText,
                        width: 75,
                        height: 75,
                      ),
                      pwWidgets.Container(
                        width: 85,
                        height: 85,
                        decoration: pwWidgets.BoxDecoration(
                          shape: pwWidgets.BoxShape.circle,
                          border: pwWidgets.Border.all(color: pw.PdfColors.blue900, width: 2),
                        ),
                        child: pwWidgets.Center(
                          child: pwWidgets.Text('المطابقة الرسمية\nختم الإدارة', textAlign: pwWidgets.TextAlign.center, style: const pwWidgets.TextStyle(fontSize: 8)),
                        ),
                      ),
                      pwWidgets.Text('توقيع الأستاذ(ة): ${widget.teacher.name}'),
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
        name: 'كشف_نقاط_${student.lastName}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إنشاء الـ PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.schoolClass.students.sort((a, b) => compareArabicNames(a.lastName, b.lastName));

    int cWeak = widget.schoolClass.students.where((s) => s.average < 10.0).length;
    int cAverage = widget.schoolClass.students.where((s) => s.average >= 10.0 && s.average < 14.0).length;
    int cGood = widget.schoolClass.students.where((s) => s.average >= 14.0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('قسم: ${widget.schoolClass.name}'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF59E0B),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'التلاميذ'),
            Tab(icon: Icon(Icons.bar_chart), text: 'الرسم البياني'),
            Tab(icon: Icon(Icons.menu_book), text: 'دفتر النصوص'),
            Tab(icon: Icon(Icons.upload_file), text: 'استيراد Excel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. قائمة التلاميذ
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: widget.schoolClass.students.length,
            itemBuilder: (context, index) {
              final student = widget.schoolClass.students[index];
              List<Student> sorted = List.from(widget.schoolClass.students)
                ..sort((a, b) => b.average.compareTo(a.average));
              int rank = sorted.indexOf(student) + 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: student.average >= 10 ? const Color(0xFF059669) : Colors.redAccent,
                    child: Text('$rank', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('${student.lastName} ${student.firstName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('المعدل: ${student.average.toStringAsFixed(2)} / 20 (${student.appreciation})'),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD97706)),
                    tooltip: 'كشف نقاط رسمي مع QR',
                    onPressed: () => _exportStudentBulletinPdf(student, rank),
                  ),
                ),
              );
            },
          ),

          // 2. الرسم البياني (fl_chart)
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text('توزيع معدلات القسم بيانيا', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
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
                                    getTitlesWidget: (v, m) {
                                      switch (v.toInt()) {
                                        case 0:
                                          return const Text('< 10');
                                        case 1:
                                          return const Text('10-14');
                                        case 2:
                                          return const Text('>= 14');
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
                                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: cWeak.toDouble(), color: Colors.redAccent, width: 24)]),
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: cAverage.toDouble(), color: Colors.orange, width: 24)]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: cGood.toDouble(), color: const Color(0xFF059669), width: 24)]),
                              ],
                            ),
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
              ? const Center(child: Text('لا توجد مذكرات دروس مسجلة.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.schoolClass.lessonNotes.length,
                  itemBuilder: (context, i) {
                    final n = widget.schoolClass.lessonNotes[i];
                    return Card(
                      child: ListTile(
                        title: Text('${n.date}: ${n.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${n.summary}\nالواجب: ${n.homework}'),
                      ),
                    );
                  },
                ),

          // 4. استيراد Excel
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_upload, size: 64, color: Color(0xFF059669)),
                  const SizedBox(height: 16),
                  const Text('استيراد قائمة التلاميذ من ملف Excel بالهاتف',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('اختيار ملف من ذاكرة الهاتف'),
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
