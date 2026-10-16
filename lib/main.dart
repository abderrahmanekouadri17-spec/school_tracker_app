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
  Map<String, String> studentStatuses; // المفتاح: رقم التسجيل regNumber

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
  String status; // حاضر، غائب، مبرر، مستخلف
  double continuousEval; // التقويم المستمر
  double exam1;          // الفرض 1
  double exam2;          // الفرض 2
  double test;           // الاختبار الفصلي
  double coefficient;    // المعامل
  int points;            // نقاط السلوك / المواظبة
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

  /// حساب معدل المادة وفق الصيغة التربوية الرسمية
  double get average {
    double averageContinuousAndExams = (continuousEval + exam1 + exam2) / 3.0;
    return (averageContinuousAndExams + (test * 2.0)) / 3.0;
  }

  /// التقدير التربوي
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
        imagePath: json['imagePath'],
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
// 2. إدارة التخزين المحلي والبيانات (STORAGE & HELPERS)
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
        debugPrint("Error decoding data: $e");
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
                    continuousEval: 16.0,
                    exam1: 14.5,
                    exam2: 15.0,
                    test: 16.0),
                Student(
                    firstName: 'فاطمة الزهراء',
                    lastName: 'قاسمي',
                    regNumber: '2026102',
                    birthDate: '22/08/2007',
                    birthPlace: 'الجلفة',
                    continuousEval: 18.0,
                    exam1: 17.0,
                    exam2: 18.5,
                    test: 17.5),
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

/// دالة مساعدة لتنظيف وترتيب الحروف العربية أبجدياً
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

/// قراءة العلامات بأمان وقبول الفاصلة أو النقطة
double? parseGrade(String val) {
  String cleaned = val.trim().replaceAll(',', '.');
  double? parsed = double.tryParse(cleaned);
  if (parsed != null && parsed >= 0.0 && parsed <= 20.0) {
    return parsed;
  }
  return null;
}

/// دالة مساعدة عامة لاستخراج النصوص من خلايا Excel بغض النظر عن نوع الخلية
String extractCellString(dynamic cell) {
  if (cell == null || cell.value == null) return '';
  final val = cell.value;
  if (val is excelPkg.TextCellValue) return val.value.text?.trim() ?? '';
  if (val is excelPkg.IntCellValue) return val.value.toString().trim();
  if (val is excelPkg.DoubleCellValue) return val.value.toString().trim();
  return val.toString().trim();
}

// ============================================================================
// 3. التطبيق الرئيسي والثيمات (MAIN APP)
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'السجل التربوي الشامل Pro 2026',
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
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A), secondary: const Color(0xFF0D9488)),
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B82F6),
            secondary: const Color(0xFF14B8A6),
            brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
      ),
      home: _isLocked
          ? PinLockScreen(onUnlock: _unlockApp)
          : InstitutionsListScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

// ============================================================================
// 4. شاشة الحماية (PIN & BIOMETRIC AUTH)
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
          localizedReason: 'يرجى المصادقة لفتح السجل التربوي الشامل 2026',
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
              colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                        backgroundColor: Color(0xFF1E3A8A),
                        radius: 40,
                        child: Icon(Icons.security, size: 40, color: Colors.white)),
                    const SizedBox(height: 20),
                    const Text('السجل التربوي الشامل',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('أدخل رمز المرور الافتراضي (1234) أو البصمة للمتابعة',
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
                          fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16))),
                        onPressed: _verifyPin,
                        child: const Text('فتح التطبيق',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _checkBiometricsAutomatically,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('المصادقة بالبصمة البيومترية'),
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
// 5. شاشة المؤسسات التعليمية (INSTITUTIONS SCREEN)
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
        title: Text(institution == null ? 'إضافة مؤسسة جديدة' : 'تعديل اسم المؤسسة'),
        content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'اسم المؤسسة والولاية')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
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

  void _changePinDialog() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير رمز الحماية (PIN)'),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'الرمز السري الجديد (4 أرقام)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (pinCtrl.text.length == 4) {
                SchoolData.appPin = pinCtrl.text;
                await SchoolData.saveData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث رمز الحماية بنجاح!')));
                }
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
        title: const Text('المؤسسات التربوية Pro 2026'),
        actions: [
          IconButton(
              icon: const Icon(Icons.lock_reset),
              tooltip: 'تغيير رمز PIN',
              onPressed: _changePinDialog),
          IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onThemeToggle),
        ],
      ),
      body: SchoolData.institutions.isEmpty
          ? const Center(child: Text('لا توجد مؤسسات مضافة بعد.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: SchoolData.institutions.length,
              itemBuilder: (context, index) {
                final inst = SchoolData.institutions[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const CircleAvatar(
                        backgroundColor: Color(0xFF1E3A8A),
                        child: Icon(Icons.school, color: Colors.white)),
                    title: Text(inst.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('عدد الأساتذة: ${inst.teachers.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showInstitutionDialog(institution: inst)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
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
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        onPressed: () => _showInstitutionDialog(),
        icon: const Icon(Icons.add),
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
                    radius: 45,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage:
                        tempImagePath != null ? FileImage(File(tempImagePath!)) : null,
                    child: tempImagePath == null
                        ? const Icon(Icons.camera_alt, size: 32, color: Colors.grey)
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

  void _deleteTeacher(Teacher teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الأستاذ'),
        content: Text('هل أنت متأكد من حذف الأستاذ "${teacher.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() {
                widget.institution.teachers.remove(teacher);
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
        title: Text(widget.institution.name),
        actions: [
          IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onThemeToggle),
        ],
      ),
      body: widget.institution.teachers.isEmpty
          ? const Center(child: Text('لا يوجد أساتذة مضافون.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.institution.teachers.length,
              itemBuilder: (context, index) {
                final teacher = widget.institution.teachers[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D9488),
                      backgroundImage: teacher.imagePath != null
                          ? FileImage(File(teacher.imagePath!))
                          : null,
                      child: teacher.imagePath == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(teacher.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('المادة: ${teacher.subject} | الأقسام: ${teacher.classes.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showTeacherDialog(teacher: teacher)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTeacher(teacher)),
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
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showTeacherDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة أستاذ'),
      ),
    );
  }
}

// ============================================================================
// 7. شاشة الأقسام والتقارير وتصدير PDF/Excel (CLASSES SCREEN)
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
        title: Text(schoolClass == null ? 'إضافة قسم جديد' : 'تعديل اسم القسم'),
        content: TextField(
            controller: classCtrl,
            decoration: const InputDecoration(hintText: 'مثال: 3 ثانوي رياضيات 1')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
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

  void _deleteClass(SchoolClass schoolClass) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القسم'),
        content: Text('هل أنت متأكد من حذف قسم "${schoolClass.name}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() {
                widget.teacher.classes.remove(schoolClass);
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

  void _showTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('جدول الحصص والتوقيت الأسبوعي'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: Column(
              children: [
                Expanded(
                  child: widget.teacher.timetable.isEmpty
                      ? const Center(child: Text('لا توجد حصص مضافة في الجدول بعد.'))
                      : ListView.builder(
                          itemCount: widget.teacher.timetable.length,
                          itemBuilder: (context, index) {
                            final item = widget.teacher.timetable[index];
                            return Card(
                              child: ListTile(
                                title: Text('${item.day} | ${item.timeSlot}'),
                                subtitle: Text('القسم: ${item.className} | القاعة: ${item.room}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    setState(() {
                                      widget.teacher.timetable.removeAt(index);
                                    });
                                    setDialogState(() {});
                                    await SchoolData.saveData();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة حصة جديدة للجدول'),
                  onPressed: () {
                    _showAddTimetableItemDialog(onAdded: () {
                      setDialogState(() {});
                      setState(() {});
                    });
                  },
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }

  void _showAddTimetableItemDialog({required VoidCallback onAdded}) {
    final dayCtrl = TextEditingController(text: 'الأحد');
    final timeCtrl = TextEditingController(text: '08:00 - 10:00');
    final classCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: 'قاعة 01');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حصة دراسية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dayCtrl, decoration: const InputDecoration(labelText: 'اليوم (الأحد - الخميس)')),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'التوقيت (مثال: 08:00 - 10:00)')),
              TextField(controller: classCtrl, decoration: const InputDecoration(labelText: 'اسم القسم')),
              TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'رقم القاعة')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (classCtrl.text.isNotEmpty) {
                setState(() {
                  widget.teacher.timetable.add(TimetableItem(
                    day: dayCtrl.text.trim(),
                    timeSlot: timeCtrl.text.trim(),
                    className: classCtrl.text.trim(),
                    room: roomCtrl.text.trim(),
                  ));
                });
                await SchoolData.saveData();
                if (mounted) Navigator.pop(context);
                onAdded();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showBackupRestoreDialog() {
    final backupCtrl = TextEditingController(text: SchoolData.exportBackupJson());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('النسخ الاحتياطي والاستعادة'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('انسخ هذا النص كنسخة احتياطية، أو الصق نسخة سابقة للاسترجاع:',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                TextField(
                    controller: backupCtrl,
                    maxLines: 6,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backupCtrl.text));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('تم نسخ البيانات بنجاح!')));
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              bool success = await SchoolData.importBackupJson(backupCtrl.text);
              if (success) {
                setState(() {});
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت استعادة البيانات بنجاح!')));
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل الاستعادة! تأكد من صحة نص البيانات.')));
                }
              }
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  /// تصدير تقرير رسمي بصيغة PDF مع دعم كامل للخط العربي
  Future<void> _exportPdfReport() async {
    try {
      final pdf = pwWidgets.Document();
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicBold = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pwWidgets.MultiPage(
          pageFormat: pw.PdfPageFormat.a4,
          textDirection: pwWidgets.TextDirection.rtl,
          theme: pwWidgets.ThemeData.withFont(base: arabicFont, bold: arabicBold),
          build: (pwWidgets.Context context) {
            return [
              pwWidgets.Center(
                child: pwWidgets.Text('الجمهورية الجزائرية الديمقراطية الشعبية',
                    style: pwWidgets.TextStyle(fontSize: 14, fontWeight: pwWidgets.FontWeight.bold)),
              ),
              pwWidgets.Center(
                child: pwWidgets.Text('وزارة التربية الوطنية - السجل البيداغوجي الشامل',
                    style: pwWidgets.TextStyle(fontSize: 12)),
              ),
              pwWidgets.Divider(thickness: 1.5),
              pwWidgets.SizedBox(height: 10),
              pwWidgets.Text('المؤسسة: ${widget.institution.name}'),
              pwWidgets.Text('الأستاذ: ${widget.teacher.name} | المادة: ${widget.teacher.subject}'),
              pwWidgets.Text('تاريخ استخراج التقرير: ${todayStr()}'),
              pwWidgets.SizedBox(height: 15),
              pwWidgets.Text('الأقسام المسجلة وإحصائياتها:',
                  style: pwWidgets.TextStyle(fontSize: 14, fontWeight: pwWidgets.FontWeight.bold)),
              pwWidgets.SizedBox(height: 8),
              ...widget.teacher.classes.map((c) {
                double classAvg = c.students.isEmpty
                    ? 0.0
                    : c.students.fold(0.0, (sum, s) => sum + s.average) / c.students.length;
                return pwWidgets.Container(
                  margin: const pwWidgets.EdgeInsets.only(bottom: 6),
                  padding: const pwWidgets.EdgeInsets.all(6),
                  decoration: pwWidgets.BoxDecoration(border: pwWidgets.Border.all(color: pw.PdfColors.grey400)),
                  child: pwWidgets.Text(
                      'القسم: ${c.name} | عدد التلاميذ: ${c.students.length} | المعدل العام للقسم: ${classAvg.toStringAsFixed(2)} / 20'),
                );
              }),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (pw.PdfPageFormat format) async => pdf.save(),
        name: 'تقرير_الاستاذ_${widget.teacher.name}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء تصدير PDF: $e')));
      }
    }
  }

  /// تصدير التقرير الشامل لملف Excel
  Future<void> _exportExcelReport() async {
    try {
      var excel = excelPkg.Excel.createExcel();
      excelPkg.Sheet sheet = excel['السجل الشامل'];

      sheet.appendRow([
        excelPkg.TextCellValue('المؤسسة التربوية:'),
        excelPkg.TextCellValue(widget.institution.name)
      ]);
      sheet.appendRow([
        excelPkg.TextCellValue('الأستاذ:'),
        excelPkg.TextCellValue(widget.teacher.name)
      ]);
      sheet.appendRow([
        excelPkg.TextCellValue('المادة:'),
        excelPkg.TextCellValue(widget.teacher.subject)
      ]);
      sheet.appendRow([
        excelPkg.TextCellValue('تاريخ التصدير:'),
        excelPkg.TextCellValue(todayStr())
      ]);
      sheet.appendRow([]); // سطر فارغ

      for (var c in widget.teacher.classes) {
        sheet.appendRow([excelPkg.TextCellValue('القسم: ${c.name}')]);
        sheet.appendRow([
          excelPkg.TextCellValue('الرقم'),
          excelPkg.TextCellValue('اللقب'),
          excelPkg.TextCellValue('الاسم'),
          excelPkg.TextCellValue('رقم التسجيل'),
          excelPkg.TextCellValue('التقويم'),
          excelPkg.TextCellValue('الفرض 1'),
          excelPkg.TextCellValue('الفرض 2'),
          excelPkg.TextCellValue('الاختبار'),
          excelPkg.TextCellValue('المعدل'),
          excelPkg.TextCellValue('التقدير'),
        ]);

        for (int i = 0; i < c.students.length; i++) {
          var s = c.students[i];
          sheet.appendRow([
            excelPkg.IntCellValue(i + 1),
            excelPkg.TextCellValue(s.lastName),
            excelPkg.TextCellValue(s.firstName),
            excelPkg.TextCellValue(s.regNumber),
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
      String path = '${directory.path}/Educational_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      file.createSync(recursive: true);
      file.writeAsBytesSync(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تصدير ملف Excel بنجاح في:\n$path')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء تصدير ملف Excel: $e')));
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
              icon: const Icon(Icons.calendar_today),
              tooltip: 'جدول الحصص والتوقيت',
              onPressed: _showTimetableDialog),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              tooltip: 'تصدير وحفظ PDF',
              onPressed: _exportPdfReport),
          IconButton(
              icon: const Icon(Icons.table_chart, color: Colors.green),
              tooltip: 'تصدير Excel',
              onPressed: _exportExcelReport),
          IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              tooltip: 'النسخ الاحتياطي',
              onPressed: _showBackupRestoreDialog),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)]),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  const Text('إجمالي الأقسام', style: TextStyle(color: Colors.white70)),
                  Text('${widget.teacher.classes.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold))
                ]),
                Container(height: 30, width: 1, color: Colors.white54),
                Column(children: [
                  const Text('إجمالي التلاميذ', style: TextStyle(color: Colors.white70)),
                  Text('$totalStudents',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold))
                ]),
              ],
            ),
          ),
          Expanded(
            child: widget.teacher.classes.isEmpty
                ? const Center(child: Text('لا توجد أقسام مضافة بعد.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.teacher.classes.length,
                    itemBuilder: (context, index) {
                      final schoolClass = widget.teacher.classes[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(
                              backgroundColor: Color(0xFF1E3A8A),
                              child: Icon(Icons.class_, color: Colors.white)),
                          title: Text(schoolClass.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text('عدد التلاميذ: ${schoolClass.students.length}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      _showClassDialog(schoolClass: schoolClass)),
                              IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteClass(schoolClass)),
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
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة قسم'),
      ),
    );
  }
}

// ============================================================================
// 8. لوحة تحكم القسم واستيراد Excel والتلاميذ (CLASS DASHBOARD)
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

  void _showAddStudentDialog() {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final birthDateCtrl = TextEditingController(text: '01/01/2007');
    final birthPlaceCtrl = TextEditingController(text: 'الجلفة');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تلميذ جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'اللقب')),
              TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(
                controller: regCtrl,
                decoration: const InputDecoration(labelText: 'رقم التسجيل (اتركه فارغاً للتوليد التلقائي)'),
              ),
              TextField(controller: birthDateCtrl, decoration: const InputDecoration(labelText: 'تاريخ الازدياد')),
              TextField(controller: birthPlaceCtrl, decoration: const InputDecoration(labelText: 'مكان الازدياد')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (firstCtrl.text.trim().isNotEmpty && lastCtrl.text.trim().isNotEmpty) {
                setState(() {
                  widget.schoolClass.students.add(Student(
                    firstName: firstCtrl.text.trim(),
                    lastName: lastCtrl.text.trim(),
                    regNumber: regCtrl.text.trim().isEmpty
                        ? 'REG${DateTime.now().millisecondsSinceEpoch % 100000}'
                        : regCtrl.text.trim(),
                    birthDate: birthDateCtrl.text.trim(),
                    birthPlace: birthPlaceCtrl.text.trim(),
                  ));
                });
                await SchoolData.saveData();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  /// استيراد قائمة التلاميذ الاحترافية من ذاكرة الهاتف مع فحص المسار والبيانات
  Future<void> _importStudentsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // يضمن توفر البايتات حتى في حال قيود Scoped Storage
      );

      if (result != null && result.files.isNotEmpty) {
        Uint8List? bytes = result.files.single.bytes;
        if (bytes == null && result.files.single.path != null) {
          bytes = await File(result.files.single.path!).readAsBytes();
        }

        if (bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تعذر قراءة ملف Excel، يرجى المحاولة ثانية.')));
          }
          return;
        }

        var excel = excelPkg.Excel.decodeBytes(bytes);
        int addedCount = 0;

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          if (rows.isEmpty) continue;

          // فحص الصف الأول لمعرفة إن كان صف عناوين
          int startIndex = 0;
          if (rows.isNotEmpty) {
            String firstCell = extractCellString(rows[0][0]);
            if (firstCell.contains('اللقب') || firstCell.contains('Nom') || firstCell.contains('الرقم')) {
              startIndex = 1; // تخطي رأس الجدول
            }
          }

          for (int i = startIndex; i < rows.length; i++) {
            var row = rows[i];
            if (row.isEmpty) continue;

            String lastName = row.isNotEmpty ? extractCellString(row[0]) : '';
            String firstName = row.length > 1 ? extractCellString(row[1]) : '';
            String regNum = row.length > 2 ? extractCellString(row[2]) : '';
            String birthDate = row.length > 3 ? extractCellString(row[3]) : '01/01/2007';
            String birthPlace = row.length > 4 ? extractCellString(row[4]) : 'الجلفة';

            // إذا كان العمود الأول رقماً ترتيبياً، قد يكون اللقب في العمود الثاني
            if (int.tryParse(lastName) != null && row.length > 2) {
              lastName = extractCellString(row[1]);
              firstName = extractCellString(row[2]);
              regNum = row.length > 3 ? extractCellString(row[3]) : '';
            }

            if (lastName.isNotEmpty || firstName.isNotEmpty) {
              if (regNum.isEmpty) {
                regNum = '2026${widget.schoolClass.students.length + addedCount + 1}';
              }
              widget.schoolClass.students.add(Student(
                lastName: lastName,
                firstName: firstName,
                regNumber: regNum,
                birthDate: birthDate.isEmpty ? '01/01/2007' : birthDate,
                birthPlace: birthPlace.isEmpty ? 'الجلفة' : birthPlace,
              ));
              addedCount++;
            }
          }
        }

        await SchoolData.saveData();
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم استيراد $addedCount تلميذاً بنجاح من ملف Excel!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل استيراد ملف Excel: $e')));
      }
    }
  }

  void _showAddNoteDialog({LessonNote? note}) {
    final dateCtrl = TextEditingController(text: note?.date ?? todayStr());
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final summaryCtrl = TextEditingController(text: note?.summary ?? '');
    final homeworkCtrl = TextEditingController(text: note?.homework ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'إضافة مذكرة درس جديد' : 'تعديل مذكرة الدرس'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'التاريخ')),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الدرس والمحور')),
              TextField(controller: summaryCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'خلاصة الدرس / الكفاءات المستهدفة')),
              TextField(controller: homeworkCtrl, decoration: const InputDecoration(labelText: 'العمل المنزلي / الواجب')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                setState(() {
                  if (note == null) {
                    widget.schoolClass.lessonNotes.add(LessonNote(
                      date: dateCtrl.text.trim(),
                      title: titleCtrl.text.trim(),
                      summary: summaryCtrl.text.trim(),
                      homework: homeworkCtrl.text.trim(),
                    ));
                  } else {
                    note.date = dateCtrl.text.trim();
                    note.title = titleCtrl.text.trim();
                    note.summary = summaryCtrl.text.trim();
                    note.homework = homeworkCtrl.text.trim();
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

  void _updateAttendanceForToday(Student student, String newStatus) {
    setState(() {
      student.status = newStatus;
      String currentToday = todayStr();

      DailyAttendanceRecord? record = widget.schoolClass.dailyRecords
          .where((d) => d.date == currentToday)
          .firstOrNull;

      if (record == null) {
        record = DailyAttendanceRecord(date: currentToday, studentStatuses: {});
        widget.schoolClass.dailyRecords.add(record);
      }
      record.studentStatuses[student.regNumber] = newStatus;
    });
    SchoolData.saveData();
  }

  /// تعديل علامات التلميذ بالتفصيل المطابق للتقويم التربوي
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
                      const SnackBar(content: Text('تم تحديث العلامات بنجاح!')));
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
    // الترتيب الأبجدي الدقيق للتلاميذ بالاعتماد على معالجة الحروف العربية
    widget.schoolClass.students.sort((a, b) => compareArabicNames(a.lastName, b.lastName));

    final filteredStudents = widget.schoolClass.students.where((s) {
      if (_studentSearchQuery.isEmpty) return true;
      final q = _studentSearchQuery.toLowerCase();
      return s.lastName.toLowerCase().contains(q) ||
          s.firstName.toLowerCase().contains(q) ||
          s.regNumber.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('قسم: ${widget.schoolClass.name}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'قائمة التلاميذ'),
            Tab(icon: Icon(Icons.menu_book), text: 'دفتر النصوص'),
            Tab(icon: Icon(Icons.event_available), text: 'سجل الحضور'),
            Tab(icon: Icon(Icons.analytics), text: 'إحصائيات القسم'),
            Tab(icon: Icon(Icons.upload_file), text: 'استيراد Excel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. تبويب قائمة التلاميذ والعلامات
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث عن تلميذ بالاسم أو اللقب أو رقم التسجيل...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: student.average >= 10.0 ? Colors.green : Colors.red,
                                child: Text('${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              title: Text('${student.lastName} ${student.firstName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              subtitle: Text(
                                  'المعدل: ${student.average.toStringAsFixed(2)}/20 (${student.appreciation}) | تقويم: ${student.continuousEval} | ف1: ${student.exam1} | ف2: ${student.exam2} | اخت: ${student.test}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    value: student.status,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'حاضر', child: Text('حاضر', style: TextStyle(color: Colors.green))),
                                      DropdownMenuItem(value: 'غائب', child: Text('غائب', style: TextStyle(color: Colors.red))),
                                      DropdownMenuItem(value: 'مبرر', child: Text('مبرر', style: TextStyle(color: Colors.blue))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        _updateAttendanceForToday(student, val);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blue),
                                    tooltip: 'تعديل العلامات',
                                    onPressed: () => _showEditStudentGradesDialog(student),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      setState(() {
                                        widget.schoolClass.students.remove(student);
                                      });
                                      await SchoolData.saveData();
                                    },
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

          // 2. تبويب دفتر النصوص (تم تصحيح خطأ .isEmpty.isEmpty هنا)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مذكرة درس جديد في دفتر النصوص'),
                  onPressed: () => _showAddNoteDialog(),
                ),
              ),
              Expanded(
                child: widget.schoolClass.lessonNotes.isEmpty
                    ? const Center(child: Text('لا توجد مذكرات دروس مسجلة بعد في دفتر النصوص.'))
                    : ListView.builder(
                        itemCount: widget.schoolClass.lessonNotes.length,
                        itemBuilder: (context, index) {
                          final note = widget.schoolClass.lessonNotes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text('${note.date}: ${note.title}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('الخلاصة: ${note.summary}\nالعمل المنزلي: ${note.homework}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAddNoteDialog(note: note),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      setState(() {
                                        widget.schoolClass.lessonNotes.removeAt(index);
                                      });
                                      await SchoolData.saveData();
                                    },
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

          // 3. سجل الحضور اليومي
          widget.schoolClass.dailyRecords.isEmpty
              ? const Center(child: Text('لا توجد جلسات حضور مسجلة بعد.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.schoolClass.dailyRecords.length,
                  itemBuilder: (context, index) {
                    final record = widget.schoolClass.dailyRecords[index];
                    int presentCount = record.studentStatuses.values.where((v) => v == 'حاضر').length;
                    int absentCount = record.studentStatuses.values.where((v) => v == 'غائب').length;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Color(0xFF0D9488),
                            child: Icon(Icons.date_range, color: Colors.white)),
                        title: Text('تاريخ الحصة: ${record.date}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الحاضرون: $presentCount | الغائبون: $absentCount'),
                      ),
                    );
                  },
                ),

          // 4. إحصائيات القسم وتحليل النتائج
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.analytics, size: 60, color: Color(0xFF1E3A8A)),
                      const SizedBox(height: 12),
                      Text('إحصائيات قسم: ${widget.schoolClass.name}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(height: 24),
                      Text('إجمالي عدد التلاميذ: ${widget.schoolClass.students.length} تلميذاً'),
                      const SizedBox(height: 8),
                      Text(
                        'المعدل العام للقسم: ${widget.schoolClass.students.isEmpty ? "0.00" : (widget.schoolClass.students.fold(0.0, (sum, s) => sum + s.average) / widget.schoolClass.students.length).toStringAsFixed(2)} / 20',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عدد الناجحين (معدل >= 10): ${widget.schoolClass.students.where((s) => s.average >= 10.0).length}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'نسبة النجاح: ${widget.schoolClass.students.isEmpty ? "0" : ((widget.schoolClass.students.where((s) => s.average >= 10.0).length / widget.schoolClass.students.length) * 100).toStringAsFixed(1)} %',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. استيراد قائمة التلاميذ من ملف Excel
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.file_upload, size: 64, color: Colors.teal),
                  const SizedBox(height: 16),
                  const Text('استيراد قائمة التلاميذ من ملف Excel (.xlsx أو .xls)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'يدعم التطبيق ملفات برنامج «رقمنة» أو الجداول المخصصة: الأعمدة تشمل اللقب، الاسم، رقم التسجيل، تاريخ الميلاد ومكان الميلاد.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('اختيار ملف Excel من الهاتف'),
                    onPressed: _importStudentsFromExcel,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة تلميذ'),
      ),
    );
  }
}
