import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SchoolData.loadData(); // تحميل البيانات المحفوظة عند فتح التطبيق
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488),
        ),
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          secondary: const Color(0xFF14B8A6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
      ),
      home: SetupInstitutionScreen(onThemeToggle: _toggleTheme, isDarkMode: _isDarkMode),
    );
  }
}

// نموذج البيانات مع الحفظ الدائم
class BehaviorLog {
  final String description;
  final int pointsChange;
  final String time;

  BehaviorLog({required this.description, required this.pointsChange, required this.time});

  Map<String, dynamic> toJson() => {'description': description, 'pointsChange': pointsChange, 'time': time};
  factory BehaviorLog.fromJson(Map<String, dynamic> json) => BehaviorLog(
        description: json['description'],
        pointsChange: json['pointsChange'],
        time: json['time'],
      );
}

class Student {
  String firstName;
  String lastName;
  String regNumber;
  String birthDate;
  String birthPlace;
  String status; // 'حاضر', 'غائب', 'هرب', 'خروج بإذن'
  String? exitTime;
  int points;
  List<BehaviorLog> logs;

  Student({
    required this.firstName,
    required this.lastName,
    required this.regNumber,
    required this.birthDate,
    required this.birthPlace,
    this.status = 'حاضر',
    this.exitTime,
    this.points = 0,
    List<BehaviorLog>? logs,
  }) : logs = logs ?? [];

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'regNumber': regNumber,
        'birthDate': birthDate,
        'birthPlace': birthPlace,
        'status': status,
        'exitTime': exitTime,
        'points': points,
        'logs': logs.map((l) => l.toJson()).toList(),
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        firstName: json['firstName'],
        lastName: json['lastName'],
        regNumber: json['regNumber'],
        birthDate: json['birthDate'],
        birthPlace: json['birthPlace'],
        status: json['status'] ?? 'حاضر',
        exitTime: json['exitTime'],
        points: json['points'] ?? 0,
        logs: json['logs'] != null ? (json['logs'] as List).map((l) => BehaviorLog.fromJson(l)).toList() : [],
      );
}

class SchoolClass {
  String name;
  List<Student> students;
  SchoolClass({required this.name, required this.students});

  Map<String, dynamic> toJson() => {
        'name': name,
        'students': students.map((s) => s.toJson()).toList(),
      };

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        name: json['name'],
        students: json['students'] != null ? (json['students'] as List).map((s) => Student.fromJson(s)).toList() : [],
      );
}

class SchoolData {
  static String institutionName = 'ثانوية السعادة';
  static String teacherName = 'الأستاذ الكريم';
  static String subjectName = 'رياضيات';
  static List<SchoolClass> classes = [];

  // حفظ البيانات في ذاكرة الهاتف الدائمة
  static Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('institutionName', institutionName);
    await prefs.setString('teacherName', teacherName);
    await prefs.setString('subjectName', subjectName);
    await prefs.setString('classesData', jsonEncode(classes.map((c) => c.toJson()).toList()));
  }

  // استرجاع البيانات المحفوظة
  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    institutionName = prefs.getString('institutionName') ?? 'ثانوية السعادة';
    teacherName = prefs.getString('teacherName') ?? 'الأستاذ الكريم';
    subjectName = prefs.getString('subjectName') ?? 'رياضيات';

    String? classesStr = prefs.getString('classesData');
    if (classesStr != null) {
      List<dynamic> decoded = jsonDecode(classesStr);
      classes = decoded.map((c) => SchoolClass.fromJson(c)).toList();
    } else {
      classes = [
        SchoolClass(name: '2 ثانوي رياضيات 1', students: [
          Student(firstName: 'أحمد', lastName: 'بن علي', regNumber: '2026101', birthDate: '15/05/2010', birthPlace: 'الجلفة', points: 5),
          Student(firstName: 'فاطمة', lastName: 'زهرة', regNumber: '2026102', birthDate: '22/08/2010', birthPlace: 'الجلفة', points: 8),
        ])
      ];
    }
  }
}

// الشاشة الأولى: إعداد المؤسسة
class SetupInstitutionScreen extends StatefulWidget {
  const SetupInstitutionScreen({super.key, required this.onThemeToggle, required this.isDarkMode});
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  @override
  State<SetupInstitutionScreen> createState() => _SetupInstitutionScreenState();
}

class _SetupInstitutionScreenState extends State<SetupInstitutionScreen> {
  final TextEditingController _controller = TextEditingController(text: SchoolData.institutionName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeToggle,
            tooltip: 'تغيير المظهر',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 64, color: Color(0xFF1E3A8A)),
                  const SizedBox(height: 16),
                  const Text('إعداد المؤسسة التربوية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('قم بإدخال أو تعديل اسم المؤسسة', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'اسم المؤسسة',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        setState(() {
                          SchoolData.institutionName = _controller.text.isEmpty ? 'ثانوية عامة' : _controller.text;
                        });
                        await SchoolData.saveData();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SetupTeacherScreen(onThemeToggle: widget.onThemeToggle, isDarkMode: widget.isDarkMode)));
                      },
                      child: const Text('التالي: بيانات الأستاذ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// الشاشة الثانية: إعداد الأستاذ والمادة
class SetupTeacherScreen extends StatefulWidget {
  const SetupTeacherScreen({super.key, required this.onThemeToggle, required this.isDarkMode});
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  @override
  State<SetupTeacherScreen> createState() => _SetupTeacherScreenState();
}

class _SetupTeacherScreenState extends State<SetupTeacherScreen> {
  final TextEditingController _teacherController = TextEditingController(text: SchoolData.teacherName);
  final TextEditingController _subjectController = TextEditingController(text: SchoolData.subjectName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(SchoolData.institutionName),
        actions: [
          IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Color(0xFF0D9488)),
                  const SizedBox(height: 16),
                  const Text('معلومات الأستاذ والمادة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _teacherController,
                    decoration: InputDecoration(
                      labelText: 'اسم الأستاذ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'المادة التعليمية',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('السابق'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            setState(() {
                              SchoolData.teacherName = _teacherController.text;
                              SchoolData.subjectName = _subjectController.text;
                            });
                            await SchoolData.saveData();
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ClassesScreen(onThemeToggle: widget.onThemeToggle, isDarkMode: widget.isDarkMode)));
                          },
                          child: const Text('التالي: الأقسام', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// الشاشة الثالثة: إدارة الأقسام والإحصائيات
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, required this.onThemeToggle, required this.isDarkMode});
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final TextEditingController _classController = TextEditingController();

  void _addClass() async {
    if (_classController.text.isNotEmpty) {
      setState(() {
        SchoolData.classes.add(SchoolClass(name: _classController.text, students: []));
        _classController.clear();
      });
      await SchoolData.saveData();
      Navigator.pop(context);
    }
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قسم جديد'),
        content: TextField(
          controller: _classController,
          decoration: const InputDecoration(hintText: 'مثال: 3 ثانوي علوم 1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: _addClass, child: const Text('إضافة')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents = SchoolData.classes.fold(0, (sum, c) => sum + c.students.length);

    return Scaffold(
      appBar: AppBar(
        title: Text('${SchoolData.subjectName} - الأقسام'),
        actions: [
          IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode), onPressed: widget.onThemeToggle),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF0D9488)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('إجمالي الأقسام', style: TextStyle(color: Colors.white70)),
                    Text('${SchoolData.classes.length}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(height: 30, width: 1, color: Colors.white54),
                Column(
                  children: [
                    const Text('إجمالي التلاميذ', style: TextStyle(color: Colors.white70)),
                    Text('$totalStudents', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: SchoolData.classes.length,
              itemBuilder: (context, index) {
                final schoolClass = SchoolData.classes[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF0D9488),
                      child: Icon(Icons.group, color: Colors.white),
                    ),
                    title: Text(schoolClass.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('عدد التلاميذ: ${schoolClass.students.length}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudentsScreen(schoolClass: schoolClass)),
                      ).then((_) => setState(() {}));
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
        onPressed: _showAddClassDialog,
        icon: const Icon(Icons.add),
        label: const Text('إضافة قسم'),
      ),
    );
  }
}

// الشاشة الرابعة: واجهة التلاميذ المتقدمة، البحث، الاستيراد الذكي، وتصدير التقارير
class StudentsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const StudentsScreen({super.key, required this.schoolClass});

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

  // تصدير ونسخ تقرير القسم
  void _exportClassReport() {
    String report = '--- تقرير القسم: ${widget.schoolClass.name} ---\n';
    report += 'المؤسسة: ${SchoolData.institutionName} | الأستاذ: ${SchoolData.teacherName} | المادة: ${SchoolData.subjectName}\n\n';
    
    for (int i = 0; i < widget.schoolClass.students.length; i++) {
      var s = widget.schoolClass.students[i];
      report += '${i + 1}. ${s.lastName} ${s.firstName} - رقم: ${s.regNumber}\n';
      report += '   الحالة: ${s.status} ${s.exitTime != null ? '(${s.exitTime})' : ''} | النقاط: ${s.points}\n';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقرير القسم الجاهز للمشاركة'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(report, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ التقرير'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ التقرير بنجاح، يمكنك لصقه في أي تطبيق!')),
              );
            },
          ),
        ],
      ),
    );
  }

  // الاستيراد الذكي من الملفات (Excel / Word / PDF عبر اللصق)
  void _showImportDialog() {
    final TextEditingController importController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استيراد قائمة التلاميذ الذكي'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'قم بنسخ الأسماء من ملف Excel أو Word أو PDF وألصقها هنا (كل تلميذ في سطر):',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: importController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'مثال:\nبن علي أحمد\nفاطمة زهرة\nيوسف إبراهيم',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (importController.text.isNotEmpty) {
                List<String> lines = importController.text.split('\n');
                int addedCount = 0;
                setState(() {
                  for (var line in lines) {
                    String cleanLine = line.trim();
                    if (cleanLine.isNotEmpty) {
                      List<String> parts = cleanLine.split(' ');
                      String lastName = parts.isNotEmpty ? parts[0] : 'تلميذ';
                      String firstName = parts.length > 1 ? parts.sublist(1).join(' ') : 'جديد';
                      
                      widget.schoolClass.students.add(Student(
                        firstName: firstName,
                        lastName: lastName,
                        regNumber: '2026${100 + widget.schoolClass.students.length + 1}',
                        birthDate: '01/01/2010',
                        birthPlace: 'الجلفة',
                      ));
                      addedCount++;
                    }
                  }
                });
                await SchoolData.saveData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم استيراد $addedCount تلميذ بنجاح وحفظهم في الذاكرة!')),
                );
              }
            },
            child: const Text('استيراد وحفظ'),
          ),
        ],
      ),
    );
  }

  void _showStudentDialog({Student? student}) {
    final firstController = TextEditingController(text: student?.firstName ?? '');
    final lastController = TextEditingController(text: student?.lastName ?? '');
    final regController = TextEditingController(text: student?.regNumber ?? '');
    final birthDateController = TextEditingController(text: student?.birthDate ?? '');
    final birthPlaceController = TextEditingController(text: student?.birthPlace ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student == null ? 'إضافة تلميذ جديد' : 'تعديل بيانات التلميذ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: lastController, decoration: const InputDecoration(labelText: 'اللقب')),
              TextField(controller: firstController, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: regController, decoration: const InputDecoration(labelText: 'رقم التسجيل')),
              TextField(controller: birthDateController, decoration: const InputDecoration(labelText: 'تاريخ الميلاد (DD/MM/YYYY)')),
              TextField(controller: birthPlaceController, decoration: const InputDecoration(labelText: 'مكان الميلاد')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (lastController.text.isNotEmpty && firstController.text.isNotEmpty) {
                setState(() {
                  if (student == null) {
                    widget.schoolClass.students.add(Student(
                      firstName: firstController.text,
                      lastName: lastController.text,
                      regNumber: regController.text,
                      birthDate: birthDateController.text,
                      birthPlace: birthPlaceController.text,
                    ));
                  } else {
                    student.firstName = firstController.text;
                    student.lastName = lastController.text;
                    student.regNumber = regController.text;
                    student.birthDate = birthDateController.text;
                    student.birthPlace = birthPlaceController.text;
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

  void _showPointsDialog(Student student, bool isAdd) {
    final reasonController = TextEditingController();
    final pointsController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'إضافة نقاط لـ ${student.lastName}' : 'خصم نقاط من ${student.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: pointsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد النقاط')),
            const SizedBox(height: 10),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'السبب (مشاركة، مشاورة، هدوء...)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              int val = int.tryParse(pointsController.text) ?? 1;
              setState(() {
                if (isAdd) {
                  student.points += val;
                  student.logs.add(BehaviorLog(description: 'إضافة نقاط: ${reasonController.text}', pointsChange: val, time: TimeOfDay.now().format(context)));
                } else {
                  student.points -= val;
                  student.logs.add(BehaviorLog(description: 'خصم نقاط: ${reasonController.text}', pointsChange: -val, time: TimeOfDay.now().format(context)));
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

  void _showStudentHistory(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سجل المتابعة: ${student.lastName} ${student.firstName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: student.logs.isEmpty
              ? const Center(child: Text('لا توجد سجلات مسجلة بعد'))
              : ListView.builder(
                  itemCount: student.logs.length,
                  itemBuilder: (context, index) {
                    final log = student.logs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: log.pointsChange > 0 ? Colors.green : Colors.red,
                        child: Text('${log.pointsChange > 0 ? '+' : ''}${log.pointsChange}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(log.description),
                      subtitle: Text('التوقيت: ${log.time}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = widget.schoolClass.students.where((student) {
      final fullName = '${student.lastName} ${student.firstName}'.toLowerCase();
      return fullName.contains(_searchQuery.toLowerCase()) || student.regNumber.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schoolClass.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير تقرير القسم',
            onPressed: _exportClassReport,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'استيراد قائمة',
            onPressed: _showImportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'ترتيب أبجدي',
            onPressed: _sortAlphabetically,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'ابحث عن تلميذ بالاسم أو رقم التسجيل...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text('لا توجد نتائج مطابقة للبحث أو القسم فارغ.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
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
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF1E3A8A),
                                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${student.lastName} ${student.firstName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text('الرقم: ${student.regNumber} | مولود في: ${student.birthDate} (${student.birthPlace})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showStudentDialog(student: student),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  DropdownButton<String>(
                                    value: student.status,
                                    items: ['حاضر', 'غائب', 'هرب', 'خروج بإذن'].map((status) {
                                      return DropdownMenuItem(value: status, child: Text(status, style: TextStyle(
                                        color: status == 'حاضر' ? Colors.green : (status == 'غائب' ? Colors.red : Colors.orange),
                                        fontWeight: FontWeight.bold,
                                      )));
                                    }).toList(),
                                    onChanged: (val) async {
                                      setState(() {
                                        student.status = val!;
                                        if (val == 'خروج بإذن' || val == 'هرب') {
                                          student.exitTime = TimeOfDay.now().format(context);
                                          student.logs.add(BehaviorLog(description: 'تغيير الحالة إلى: $val', pointsChange: 0, time: student.exitTime!));
                                        }
                                      });
                                      await SchoolData.saveData();
                                    },
                                  ),
                                  Row(
                                    children: [
                                      Text('النقاط: ${student.points}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _showPointsDialog(student, true)),
                                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => _showPointsDialog(student, false)),
                                      IconButton(icon: const Icon(Icons.history, color: Colors.indigo), tooltip: 'السجل', onPressed: () => _showStudentHistory(student)),
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
