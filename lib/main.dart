import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SchoolData.loadData();
  runApp(const SchoolTrackerApp());
}

class SchoolTrackerApp extends StatefulWidget {
  const SchoolTrackerApp({super.key});

  @override
  State<SchoolTrackerApp> createState() => _SchoolTrackerAppState();
}

class _SchoolTrackerAppState extends State<SchoolTrackerApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'السجل التربوي الشامل',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A), secondary: const Color(0xFF0D9488)),
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6), secondary: const Color(0xFF14B8A6), brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
      ),
      home: InstitutionsListScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

// ==========================================
// نماذج البيانات (Models) مع سجل الأيام التاريخي
// ==========================================
class BehaviorLog {
  final String description;
  final int pointsChange;
  final String time;
  final String? reason;
  final String date;

  BehaviorLog({required this.description, required this.pointsChange, required this.time, this.reason, required this.date});

  Map<String, dynamic> toJson() => {'description': description, 'pointsChange': pointsChange, 'time': time, 'reason': reason, 'date': date};
  factory BehaviorLog.fromJson(Map<String, dynamic> json) => BehaviorLog(
        description: json['description'] ?? '',
        pointsChange: json['pointsChange'] ?? 0,
        time: json['time'] ?? '',
        reason: json['reason'],
        date: json['date'] ?? 'غير محدد',
      );
}

class LessonNote {
  String date;
  String title;
  String summary;
  String homework;
  LessonNote({required this.date, required this.title, required this.summary, required this.homework});
  Map<String, dynamic> toJson() => {'date': date, 'title': title, 'summary': summary, 'homework': homework};
  factory LessonNote.fromJson(Map<String, dynamic> json) => LessonNote(date: json['date'], title: json['title'], summary: json['summary'], homework: json['homework']);
}

// نموذج لحفظ السجل اليومي الكامل للقسم في تاريخ محدد
class DailyAttendanceRecord {
  String date; // مثال: 12/10/2026
  List<Map<String, String>> studentStatuses; // اسم التلميذ، حالته، التوقيت، السبب

  DailyAttendanceRecord({required this.date, required this.studentStatuses});

  Map<String, dynamic> toJson() => {'date': date, 'studentStatuses': studentStatuses};
  factory DailyAttendanceRecord.fromJson(Map<String, dynamic> json) => DailyAttendanceRecord(
        date: json['date'] ?? '',
        studentStatuses: json['studentStatuses'] != null ? List<Map<String, String>>.from((json['studentStatuses'] as List).map((e) => Map<String, String>.from(e))) : [],
      );
}

class Student {
  String firstName;
  String lastName;
  String regNumber;
  String birthDate;
  String birthPlace;
  String status;
  String? exitTime;
  String? exitReason;
  int points;
  double exam1;
  double exam2;
  double test;
  double coefficient;
  List<BehaviorLog> logs;

  Student({
    required this.firstName,
    required this.lastName,
    required this.regNumber,
    required this.birthDate,
    required this.birthPlace,
    this.status = 'حاضر',
    this.exitTime,
    this.exitReason,
    this.points = 0,
    this.exam1 = 0.0,
    this.exam2 = 0.0,
    this.test = 0.0,
    this.coefficient = 1.0,
    List<BehaviorLog>? logs,
  }) : logs = logs ?? [];

  double get average => ((exam1 + exam2 + (test * 2)) / 4);

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'regNumber': regNumber,
        'birthDate': birthDate,
        'birthPlace': birthPlace,
        'status': status,
        'exitTime': exitTime,
        'exitReason': exitReason,
        'points': points,
        'exam1': exam1,
        'exam2': exam2,
        'test': test,
        'coefficient': coefficient,
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        regNumber: json['regNumber'] ?? '',
        birthDate: json['birthDate'] ?? '',
        birthPlace: json['birthPlace'] ?? '',
        status: json['status'] ?? 'حاضر',
        exitTime: json['exitTime'],
        exitReason: json['exitReason'],
        points: json['points'] ?? 0,
        exam1: (json['exam1'] ?? 0.0).toDouble(),
        exam2: (json['exam2'] ?? 0.0).toDouble(),
        test: (json['test'] ?? 0.0).toDouble(),
        coefficient: (json['coefficient'] ?? 1.0).toDouble(),
        logs: json['logs'] != null ? (json['logs'] as List).map((l) => BehaviorLog.fromJson(l)).toList() : [],
      );
}

class SchoolClass {
  String name;
  List<Student> students;
  List<LessonNote> lessonNotes;
  List<DailyAttendanceRecord> dailyRecords; // الأرشيف السنوي لأيام القسم

  SchoolClass({required this.name, required this.students, List<LessonNote>? lessonNotes, List<DailyAttendanceRecord>? dailyRecords})
      : lessonNotes = lessonNotes ?? [],
        dailyRecords = dailyRecords ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'students': students.map((s) => s.toJson()).toList(),
        'lessonNotes': lessonNotes.map((l) => l.toJson()).toList(),
        'dailyRecords': dailyRecords.map((d) => d.toJson()).toList(),
      };

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        name: json['name'] ?? '',
        students: json['students'] != null ? (json['students'] as List).map((s) => Student.fromJson(s)).toList() : [],
        lessonNotes: json['lessonNotes'] != null ? (json['lessonNotes'] as List).map((l) => LessonNote.fromJson(l)).toList() : [],
        dailyRecords: json['dailyRecords'] != null ? (json['dailyRecords'] as List).map((d) => DailyAttendanceRecord.fromJson(d)).toList() : [],
      );
}

class Teacher {
  String name;
  String subject;
  List<SchoolClass> classes;

  Teacher({required this.name, required this.subject, List<SchoolClass>? classes}) : classes = classes ?? [];

  Map<String, dynamic> toJson() => {'name': name, 'subject': subject, 'classes': classes.map((c) => c.toJson()).toList()};
  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        name: json['name'] ?? '',
        subject: json['subject'] ?? '',
        classes: json['classes'] != null ? (json['classes'] as List).map((c) => SchoolClass.fromJson(c)).toList() : [],
      );
}

class Institution {
  String name;
  List<Teacher> teachers;

  Institution({required this.name, List<Teacher>? teachers}) : teachers = teachers ?? [];

  Map<String, dynamic> toJson() => {'name': name, 'teachers': teachers.map((t) => t.toJson()).toList()};
  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
        name: json['name'] ?? '',
        teachers: json['teachers'] != null ? (json['teachers'] as List).map((t) => Teacher.fromJson(t)).toList() : [],
      );
}

class SchoolData {
  static List<Institution> institutions = [];

  static Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('institutionsData', jsonEncode(institutions.map((i) => i.toJson()).toList()));
  }

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? dataStr = prefs.getString('institutionsData');
    if (dataStr != null) {
      List<dynamic> decoded = jsonDecode(dataStr);
      institutions = decoded.map((i) => Institution.fromJson(i)).toList();
    } else {
      institutions = [
        Institution(
          name: 'ثانوية السعادة',
          teachers: [
            Teacher(
              name: 'الأستاذ الكريم',
              subject: 'رياضيات',
              classes: [
                SchoolClass(name: '2 ثانوي رياضيات 1', students: [
                  Student(firstName: 'أحمد', lastName: 'بن علي', regNumber: '2026101', birthDate: '15/05/2010', birthPlace: 'الجلفة', points: 5, exam1: 14, exam2: 15, test: 16),
                  Student(firstName: 'فاطمة', lastName: 'زهرة', regNumber: '2026102', birthDate: '22/08/2010', birthPlace: 'الجلفة', points: 8, exam1: 17, exam2: 18, test: 17.5),
                ])
              ],
            )
          ],
        )
      ];
    }
  }

  static String exportBackupJson() => jsonEncode(institutions.map((i) => i.toJson()).toList());

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

// ==========================================
// 1. شاشة إدارة المؤسسات
// ==========================================
class InstitutionsListScreen extends StatefulWidget {
  const InstitutionsListScreen({super.key, required this.onThemeToggle, required this.isDarkMode});
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
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم المؤسسة')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  if (institution == null) {
                    SchoolData.institutions.add(Institution(name: nameCtrl.text));
                  } else {
                    institution.name = nameCtrl.text;
                  }
                });
                await SchoolData.saveData();
                Navigator.pop(context);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() { SchoolData.institutions.remove(institution); });
              await SchoolData.saveData();
              Navigator.pop(context);
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
        title: const Text('المؤسسات التربوية'),
        actions: [
          IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1E3A8A), child: Icon(Icons.school, color: Colors.white)),
                    title: Text(inst.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('عدد الأساتذة: ${inst.teachers.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showInstitutionDialog(institution: inst)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteInstitution(inst)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TeachersListScreen(institution: inst, onThemeToggle: widget.onThemeToggle, isDarkMode: widget.isDarkMode))).then((_) => setState(() {}));
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

// ==========================================
// 2. شاشة إدارة الأساتذة والمواد
// ==========================================
class TeachersListScreen extends StatefulWidget {
  final Institution institution;
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const TeachersListScreen({super.key, required this.institution, required this.onThemeToggle, required this.isDarkMode});

  @override
  State<TeachersListScreen> createState() => _TeachersListScreenState();
}

class _TeachersListScreenState extends State<TeachersListScreen> {
  void _showTeacherDialog({Teacher? teacher}) {
    final nameCtrl = TextEditingController(text: teacher?.name ?? '');
    final subjectCtrl = TextEditingController(text: teacher?.subject ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(teacher == null ? 'إضافة أستاذ جديد' : 'تعديل بيانات الأستاذ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الأستاذ')),
            const SizedBox(height: 10),
            TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'المادة التعليمية')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && subjectCtrl.text.isNotEmpty) {
                setState(() {
                  if (teacher == null) {
                    widget.institution.teachers.add(Teacher(name: nameCtrl.text, subject: subjectCtrl.text));
                  } else {
                    teacher.name = nameCtrl.text;
                    teacher.subject = subjectCtrl.text;
                  }
                });
                await SchoolData.saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() { widget.institution.teachers.remove(teacher); });
              await SchoolData.saveData();
              Navigator.pop(context);
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
          IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const CircleAvatar(backgroundColor: Color(0xFF0D9488), child: Icon(Icons.person, color: Colors.white)),
                    title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('المادة: ${teacher.subject} | الأقسام: ${teacher.classes.length}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showTeacherDialog(teacher: teacher)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTeacher(teacher)),
                        const Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ClassesScreen(institution: widget.institution, teacher: teacher))).then((_) => setState(() {}));
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

// ==========================================
// 3. شاشة إدارة الأقسام والأرشيف السنوي
// ==========================================
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
        content: TextField(controller: classCtrl, decoration: const InputDecoration(hintText: 'مثال: 3 ثانوي علوم 1')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (classCtrl.text.isNotEmpty) {
                setState(() {
                  if (schoolClass == null) {
                    widget.teacher.classes.add(SchoolClass(name: classCtrl.text, students: []));
                  } else {
                    schoolClass.name = classCtrl.text;
                  }
                });
                await SchoolData.saveData();
                Navigator.pop(context);
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              setState(() { widget.teacher.classes.remove(schoolClass); });
              await SchoolData.saveData();
              Navigator.pop(context);
            },
            child: const Text('حذف'),
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
                const Text('انسخ هذا الكود كنسخة احتياطية لبياناتك:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                TextField(controller: backupCtrl, maxLines: 6, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ'),
            onPressed: () { Clipboard.setData(ClipboardData(text: backupCtrl.text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ البيانات!'))); },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () async {
              bool success = await SchoolData.importBackupJson(backupCtrl.text);
              if (success) { setState(() {}); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استعادة البيانات بنجاح!'))); }
              else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الاستعادة!'))); }
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents = widget.teacher.classes.fold(0, (sum, c) => sum + c.students.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.teacher.name} (${widget.teacher.subject})'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_backup_restore), tooltip: 'النسخ الاحتياطي', onPressed: _showBackupRestoreDialog),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)]), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [const Text('إجمالي الأقسام', style: TextStyle(color: Colors.white70)), Text('${widget.teacher.classes.length}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
                Container(height: 30, width: 1, color: Colors.white54),
                Column(children: [const Text('إجمالي التلاميذ', style: TextStyle(color: Colors.white70)), Text('$totalStudents', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))]),
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
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: const CircleAvatar(backgroundColor: Color(0xFF0D9488), child: Icon(Icons.group, color: Colors.white)),
                          title: Text(schoolClass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text('عدد التلاميذ: ${schoolClass.students.length}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showClassDialog(schoolClass: schoolClass)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteClass(schoolClass)),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ClassDashboardScreen(institution: widget.institution, teacher: widget.teacher, schoolClass: schoolClass))).then((_) => setState(() {}));
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showClassDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة قسم'),
      ),
    );
  }
}

// ==========================================
// 4. مركز قيادة القسم (Class Dashboard)
// ==========================================
class ClassDashboardScreen extends StatelessWidget {
  final Institution institution;
  final Teacher teacher;
  final SchoolClass schoolClass;
  const ClassDashboardScreen({super.key, required this.institution, required this.teacher, required this.schoolClass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(schoolClass.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            DashboardCard(title: 'قائمة التلاميذ', subtitle: '${schoolClass.students.length} تلميذ', icon: Icons.people, color: const Color(0xFF1E3A8A), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentsScreen(institution: institution, teacher: teacher, schoolClass: schoolClass)))),
            DashboardCard(title: 'وضع الحصة السريع', subtitle: 'نداء وسرعة حضور', icon: Icons.bolt, color: const Color(0xFF0D9488), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuickRollCallScreen(schoolClass: schoolClass)))),
            DashboardCard(title: 'دفتر النصوص', subtitle: '${schoolClass.lessonNotes.length} درس مسجل', icon: Icons.menu_book, color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LessonNotesScreen(schoolClass: schoolClass)))),
            DashboardCard(title: 'سجل القسم اليومي', subtitle: 'أرشيف أيام السنة', icon: Icons.calendar_month, color: Colors.brown, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ClassArchiveScreen(schoolClass: schoolClass)))),
            DashboardCard(title: 'حساب المعدلات', subtitle: 'الفرض والاختبار والترتيب', icon: Icons.calculate, color: Colors.deepOrange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GradesScreen(schoolClass: schoolClass)))),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const DashboardCard({super.key, required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(backgroundColor: color.withOpacity(0.15), radius: 28, child: Icon(icon, size: 32, color: color)),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. شاشة أرشيف سجل القسم اليومي خلال كل أيام السنة
// ==========================================
class ClassArchiveScreen extends StatelessWidget {
  final SchoolClass schoolClass;
  const ClassArchiveScreen({super.key, required this.schoolClass});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('أرشيف سجل القسم: ${schoolClass.name}')),
      body: schoolClass.dailyRecords.isEmpty
          ? const Center(child: Text('لا توجد سجلات يومية محفوظة بعد.\n(يتم حفظ السجل تلقائياً عند إتمام وضع الحصة السريع).', textAlign: TextAlign.center))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: schoolClass.dailyRecords.length,
              itemBuilder: (context, index) {
                final record = schoolClass.dailyRecords[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1E3A8A), child: Icon(Icons.date_range, color: Colors.white)),
                    title: Text('تاريخ الحصة: ${record.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('عدد الحالات المسجلة: ${record.studentStatuses.length} تلميذ'),
                    children: [
                      const Divider(),
                      ...record.studentStatuses.map((st) => ListTile(
                            dense: true,
                            title: Text('${st['name']}'),
                            subtitle: Text('الحالة: ${st['status']} ${st['reason'] != null && st['reason'] != "" ? "| السبب: ${st['reason']}" : ""}'),
                            trailing: Text('${st['time']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// 6. دفتر النصوص الرقمي
// ==========================================
class LessonNotesScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const LessonNotesScreen({super.key, required this.schoolClass});

  @override
  State<LessonNotesScreen> createState() => _LessonNotesScreenState();
}

class _LessonNotesScreenState extends State<LessonNotesScreen> {
  void _showAddNoteDialog({LessonNote? note}) {
    final dateCtrl = TextEditingController(text: note?.date ?? '12/10/2026');
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final summaryCtrl = TextEditingController(text: note?.summary ?? '');
    final homeworkCtrl = TextEditingController(text: note?.homework ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'تسجيل درس جديد' : 'تعديل الدرس'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'التاريخ')),
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الدرس')),
              TextField(controller: summaryCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ملخص العناصر المنجزة')),
              TextField(controller: homeworkCtrl, decoration: const InputDecoration(labelText: 'الواجب المنزلي')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  if (note == null) {
                    widget.schoolClass.lessonNotes.add(LessonNote(date: dateCtrl.text, title: titleCtrl.text, summary: summaryCtrl.text, homework: homeworkCtrl.text));
                  } else {
                    note.date = dateCtrl.text;
                    note.title = titleCtrl.text;
                    note.summary = summaryCtrl.text;
                    note.homework = homeworkCtrl.text;
                  }
                });
                await SchoolData.saveData();
                Navigator.pop(context);
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
      appBar: AppBar(title: Text('دفتر النصوص: ${widget.schoolClass.name}')),
      body: widget.schoolClass.lessonNotes.isEmpty
          ? const Center(child: Text('لا توجد دروس مسجلة بعد.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.schoolClass.lessonNotes.length,
              itemBuilder: (context, index) {
                final note = widget.schoolClass.lessonNotes[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A))),
                            Text(note.date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const Divider(height: 16),
                        Text('الملخص: ${note.summary}'),
                        const SizedBox(height: 8),
                        Text('الواجب: ${note.homework}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showAddNoteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==========================================
// 7. وضع الحصة السريع (مع الأرشفة اليومية التلقائية)
// ==========================================
class QuickRollCallScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const QuickRollCallScreen({super.key, required this.schoolClass});

  @override
  State<QuickRollCallScreen> createState() => _QuickRollCallScreenState();
}

class _QuickRollCallScreenState extends State<QuickRollCallScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.schoolClass.students.isEmpty) {
      return Scaffold(appBar: AppBar(title: const Text('وضع الحصة السريع')), body: const Center(child: Text('لا يوجد تلاميذ في هذا القسم.')));
    }

    if (currentIndex >= widget.schoolClass.students.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('وضع الحصة السريع')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text('تم إكمال وحفظ نداء الحصة وأرشفته في السجل السنوي بنجاح!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => setState(() => currentIndex = 0), child: const Text('إعادة النداء')),
            ],
          ),
        ),
      );
    }

    final student = widget.schoolClass.students[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('نداء الحصة (${currentIndex + 1}/${widget.schoolClass.students.length})')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircleAvatar(backgroundColor: const Color(0xFF1E3A8A), radius: 40, child: Text('${currentIndex + 1}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 20),
                    Text('${student.lastName} ${student.firstName}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('رقم التسجيل: ${student.regNumber}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RollButton(label: 'حاضر', color: Colors.green, icon: Icons.check, onTap: () => _setStatus(student, 'حاضر')),
                RollButton(label: 'غائب', color: Colors.red, icon: Icons.close, onTap: () => _setStatus(student, 'غائب')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RollButton(label: 'هرب', color: Colors.deepOrange, icon: Icons.directions_run, onTap: () => _handleExitDetails(student, 'هرب')),
                RollButton(label: 'إذن', color: Colors.amber.shade800, icon: Icons.exit_to_app, onTap: () => _handleExitDetails(student, 'خروج بإذن')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleExitDetails(Student student, String status) {
    TimeOfDay selectedTime = TimeOfDay.now();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('تفاصيل حالة: $status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.indigo),
                title: Text('التوقيت: ${selectedTime.format(context)}'),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showTimePicker(context: context, initialTime: selectedTime);
                  if (picked != null) { setDialogState(() { selectedTime = picked; }); }
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: reasonCtrl, decoration: InputDecoration(labelText: 'السبب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _setStatus(student, status, customTime: selectedTime.format(context), reason: reasonCtrl.text.isEmpty ? 'بدون سبب' : reasonCtrl.text);
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  void _setStatus(Student student, String status, {String? customTime, String? reason}) async {
    String todayStr = '12/10/2026'; // التاريخ الحالي للحصة
    setState(() {
      student.status = status;
      if (status == 'هرب' || status == 'خروج بإذن') {
        student.exitTime = customTime ?? TimeOfDay.now().format(context);
        student.exitReason = reason;
      } else {
        student.exitTime = null;
        student.exitReason = null;
      }
      student.logs.add(BehaviorLog(
        description: 'حالة الحصة: $status',
        pointsChange: 0,
        time: student.exitTime ?? TimeOfDay.now().format(context),
        reason: student.exitReason,
        date: todayStr,
      ));

      // أرشفة السجل اليومي للقسم
      DailyAttendanceRecord? todayRecord = widget.schoolClass.dailyRecords.where((d) => d.date == todayStr).firstOrNull;
      Map<String, String> statusMap = {
        'name': '${student.lastName} ${student.firstName}',
        'status': status,
        'time': student.exitTime ?? '-',
        'reason': student.exitReason ?? '-'
      };
      if (todayRecord != null) {
        todayRecord.studentStatuses.removeWhere((s) => s['name'] == '${student.lastName} ${student.firstName}');
        todayRecord.studentStatuses.add(statusMap);
      } else {
        widget.schoolClass.dailyRecords.add(DailyAttendanceRecord(date: todayStr, studentStatuses: [statusMap]));
      }

      currentIndex++;
    });
    await SchoolData.saveData();
  }
}

class RollButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const RollButton({super.key, required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

// ==========================================
// 8. حساب المعدلات والترتيب الفصلي
// ==========================================
class GradesScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const GradesScreen({super.key, required this.schoolClass});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  void _showGradeDialog(Student student) {
    final e1 = TextEditingController(text: student.exam1.toString());
    final e2 = TextEditingController(text: student.exam2.toString());
    final test = TextEditingController(text: student.test.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إدخال علامات: ${student.lastName} ${student.firstName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: e1, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الفرض الأول')),
            TextField(controller: e2, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الفرض الثاني')),
            TextField(controller: test, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الاختبار (معامل 2)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                student.exam1 = double.tryParse(e1.text) ?? student.exam1;
                student.exam2 = double.tryParse(e2.text) ?? student.exam2;
                student.test = double.tryParse(test.text) ?? student.test;
              });
              await SchoolData.saveData();
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Student> sortedStudents = List.from(widget.schoolClass.students);
    sortedStudents.sort((a, b) => b.average.compareTo(a.average));

    return Scaffold(
      appBar: AppBar(title: Text('حساب المعدلات والترتيب: ${widget.schoolClass.name}')),
      body: sortedStudents.isEmpty
          ? const Center(child: Text('لا توجد تلاميذ مسجلين.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedStudents.length,
              itemBuilder: (context, index) {
                final student = sortedStudents[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? Colors.amber : (index == 1 ? Colors.grey : (index == 2 ? Colors.brown : const Color(0xFF1E3A8A))),
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${student.lastName} ${student.firstName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('الفرض1: ${student.exam1} | الفرض2: ${student.exam2} | الاختبار: ${student.test}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${student.average.toStringAsFixed(2)} / 20', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D9488))),
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showGradeDialog(student)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// 9. واجهة التلاميذ الشاملة (مع السجل التاريخي الفردي لكل تلميذ)
// ==========================================
class StudentsScreen extends StatefulWidget {
  final Institution institution;
  final Teacher teacher;
  final SchoolClass schoolClass;
  const StudentsScreen({super.key, required this.institution, required this.teacher, required this.schoolClass});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _searchQuery = '';

  void _sortAlphabetically() async {
    setState(() {
      widget.schoolClass.students.sort((a, b) => a.lastName.compareTo(b.lastName));
    });
    await SchoolData.saveData();
  }

  void _exportExcelCsv() {
    String csv = 'اللقب,الاسم,رقم التسجيل,الحالة,التوقيت,السبب,النقاط,المعدل\n';
    for (var s in widget.schoolClass.students) {
      csv += '${s.lastName},${s.firstName},${s.regNumber},${s.status},${s.exitTime ?? "-"},${s.exitReason ?? "-"},${s.points},${s.average}\n';
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصدير بيانات القسم (CSV / Excel)'),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ البيانات'),
            onPressed: () { Clipboard.setData(ClipboardData(text: csv)); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ بنجاح!'))); },
          ),
        ],
      ),
    );
  }

  void _showStudentHistory(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('السجل التاريخي الشامل: ${student.lastName} ${student.firstName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: student.logs.isEmpty
              ? const Center(child: Text('لا توجد سجلات تاريخية محفوظة لهذا التلميذ.'))
              : ListView.builder(
                  itemCount: student.logs.length,
                  itemBuilder: (context, index) {
                    final log = student.logs[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: log.pointsChange >= 0 ? Colors.green : Colors.red,
                          child: Text('${log.pointsChange >= 0 ? "+" : ""}${log.pointsChange}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(log.description),
                        subtitle: Text('التاريخ: ${log.date} | التوقيت: ${log.time}${log.reason != null ? " | السبب: ${log.reason}" : ""}'),
                      ),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
      ),
    );
  }

  void _showStatusDialog(Student student, String newStatus) {
    if (newStatus == 'هرب' || newStatus == 'خروج بإذن') {
      TimeOfDay selectedTime = TimeOfDay.now();
      final reasonCtrl = TextEditingController(text: student.exitReason ?? '');

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('تفاصيل: $newStatus'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.indigo),
                  title: Text('التوقيت: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: selectedTime);
                    if (picked != null) { setDialogState(() { selectedTime = picked; }); }
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: reasonCtrl, decoration: InputDecoration(labelText: 'السبب', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  String todayStr = '12/10/2026';
                  setState(() {
                    student.status = newStatus;
                    student.exitTime = selectedTime.format(context);
                    student.exitReason = reasonCtrl.text.isEmpty ? 'بدون سبب' : reasonCtrl.text;
                    student.logs.add(BehaviorLog(
                      description: 'الحالة: $newStatus',
                      pointsChange: 0,
                      time: student.exitTime!,
                      reason: student.exitReason,
                      date: todayStr,
                    ));
                  });
                  await SchoolData.saveData();
                  Navigator.pop(context);
                },
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        student.status = newStatus;
        student.exitTime = null;
        student.exitReason = null;
      });
      SchoolData.saveData();
    }
  }

  void _showStudentDialog({Student? student}) {
    final firstCtrl = TextEditingController(text: student?.firstName ?? '');
    final lastCtrl = TextEditingController(text: student?.lastName ?? '');
    final regCtrl = TextEditingController(text: student?.regNumber ?? '');
    final birthDateCtrl = TextEditingController(text: student?.birthDate ?? '');
    final birthPlaceCtrl = TextEditingController(text: student?.birthPlace ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student == null ? 'إضافة تلميذ' : 'تعديل تلميذ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'اللقب')),
              TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: regCtrl, decoration: const InputDecoration(labelText: 'رقم التسجيل')),
              TextField(controller: birthDateCtrl, decoration: const InputDecoration(labelText: 'تاريخ الميلاد')),
              TextField(controller: birthPlaceCtrl, decoration: const InputDecoration(labelText: 'مكان الميلاد')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (lastCtrl.text.isNotEmpty && firstCtrl.text.isNotEmpty) {
                setState(() {
                  if (student == null) {
                    widget.schoolClass.students.add(Student(firstName: firstCtrl.text, lastName: lastCtrl.text, regNumber: regCtrl.text, birthDate: birthDateCtrl.text, birthPlace: birthPlaceCtrl.text));
                  } else {
                    student.firstName = firstCtrl.text;
                    student.lastName = lastCtrl.text;
                    student.regNumber = regCtrl.text;
                    student.birthDate = birthDateCtrl.text;
                    student.birthPlace = birthPlaceCtrl.text;
                  }
                });
                await SchoolData.saveData();
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(Student student) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تلميذ'),
        content: Text('هل أنت متأكد من حذف التلميذ "${student.lastName} ${student.firstName}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { setState(() { widget.schoolClass.students.remove(student); }); await SchoolData.saveData(); Navigator.pop(context); }, child: const Text('حذف')),
        ],
      ),
    );
  }

  void _showPointsDialog(Student student, bool isAdd) {
    final reasonCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'إضافة نقاط' : 'خصم نقاط'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: pointsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العدد')),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'السبب')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              int val = int.tryParse(pointsCtrl.text) ?? 1;
              String todayStr = '12/10/2026';
              setState(() {
                if (isAdd) {
                  student.points += val;
                  student.logs.add(BehaviorLog(description: 'إضافة نقاط: ${reasonCtrl.text}', pointsChange: val, time: TimeOfDay.now().format(context), reason: reasonCtrl.text, date: todayStr));
                } else {
                  student.points -= val;
                  student.logs.add(BehaviorLog(description: 'خصم نقاط: ${reasonCtrl.text}', pointsChange: -val, time: TimeOfDay.now().format(context), reason: reasonCtrl.text, date: todayStr));
                }
              });
              await SchoolData.saveData();
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.schoolClass.students.where((s) {
      final name = '${s.lastName} ${s.firstName}'.toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || s.regNumber.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schoolClass.name),
        actions: [
          IconButton(icon: const Icon(Icons.table_chart), tooltip: 'تصدير Excel', onPressed: _exportExcelCsv),
          IconButton(icon: const Icon(Icons.sort_by_alpha), tooltip: 'ترتيب أبجدي', onPressed: _sortAlphabetically),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(hintText: 'ابحث عن تلميذ...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد نتائج.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(backgroundColor: const Color(0xFF1E3A8A), child: Text('${index + 1}', style: const TextStyle(color: Colors.white))),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${student.lastName} ${student.firstName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text('رقم: ${student.regNumber}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showStudentDialog(student: student)),
                                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStudent(student)),
                                    ],
                                  ),
                                ],
                              ),
                              if (student.exitTime != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text('التوقيت: ${student.exitTime} | السبب: ${student.exitReason ?? "غير محدد"}', style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                                ),
                              ],
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  DropdownButton<String>(
                                    value: student.status,
                                    items: ['حاضر', 'غائب', 'هرب', 'خروج بإذن'].map((st) => DropdownMenuItem(value: st, child: Text(st, style: TextStyle(color: st == 'حاضر' ? Colors.green : (st == 'غائب' ? Colors.red : Colors.orange), fontWeight: FontWeight.bold)))).toList(),
                                    onChanged: (val) {
                                      if (val != null) _showStatusDialog(student, val);
                                    },
                                  ),
                                  Row(
                                    children: [
                                      Text('النقاط: ${student.points}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _showPointsDialog(student, true)),
                                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _showPointsDialog(student, false)),
                                      IconButton(icon: const Icon(Icons.history, color: Colors.indigo, tooltip: 'السجل التاريخي'), onPressed: () => _showStudentHistory(student)),
                                    ],
                                  ),
                                ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
