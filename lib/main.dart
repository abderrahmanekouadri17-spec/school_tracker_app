import 'package:flutter/material.dart';

void main() {
  runApp(const SchoolTrackerApp());
}

class SchoolTrackerApp extends StatelessWidget {
  const SchoolTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'السجل التربوي الشامل',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // كحلي فخم
          secondary: const Color(0xFF0D9488), // تيل عصري
        ),
        useMaterial3: true,
        fontFamily: 'Cairo', // أو الخط الافتراضي الداعم للعربية
      ),
      home: const SetupInstitutionScreen(),
    );
  }
}

// 1. نموذج البيانات العام
class SchoolData {
  static String institutionName = 'ثانوية السعادة';
  static String teacherName = 'الأستاذ الكريم';
  static String subjectName = 'رياضيات';
  static List<SchoolClass> classes = [
    SchoolClass(name: '2 ثانوي رياضيات 1', students: [
      Student(
        firstName: 'أحمد',
        lastName: 'بن علي',
        regNumber: '2026101',
        birthDate: '15/05/2010',
        birthPlace: 'الجلفة',
        points: 5,
      ),
      Student(
        firstName: 'فاطمة',
        lastName: 'زهرة',
        regNumber: '2026102',
        birthDate: '22/08/2010',
        birthPlace: 'الجلفة',
        points: 8,
      ),
    ])
  ];
}

class SchoolClass {
  String name;
  List<Student> students;
  SchoolClass({required this.name, required this.students});
}

class BehaviorLog {
  final String description;
  final int pointsChange;
  final String time;

  BehaviorLog({required this.description, required this.pointsChange, required this.time});
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
}

// ------------------------------------------------------------------
// الشاشة الأولى: إعداد اسم المؤسسة
// ------------------------------------------------------------------
class SetupInstitutionScreen extends StatefulWidget {
  const SetupInstitutionScreen({super.key});

  @override
  State<SetupInstitutionScreen> createState() => _SetupInstitutionScreenState();
}

class _SetupInstitutionScreenState extends State<SetupInstitutionScreen> {
  final TextEditingController _controller = TextEditingController(text: SchoolData.institutionName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                      onPressed: () {
                        setState(() {
                          SchoolData.institutionName = _controller.text.isEmpty ? 'ثانوية عامة' : _controller.text;
                        });
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupTeacherScreen()));
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

// ------------------------------------------------------------------
// الشاشة الثانية: إعداد الأستاذ والمادة
// ------------------------------------------------------------------
class SetupTeacherScreen extends StatefulWidget {
  const SetupTeacherScreen({super.key});

  @override
  State<SetupTeacherScreen> createState() => _SetupTeacherScreenState();
}

class _SetupTeacherScreenState extends State<SetupTeacherScreen> {
  final TextEditingController _teacherController = TextEditingController(text: SchoolData.teacherName);
  final TextEditingController _subjectController = TextEditingController(text: SchoolData.subjectName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: Text(SchoolData.institutionName), backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
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
                          onPressed: () {
                            setState(() {
                              SchoolData.teacherName = _teacherController.text;
                              SchoolData.subjectName = _subjectController.text;
                            });
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ClassesScreen()));
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

// ------------------------------------------------------------------
// الشاشة الثالثة: إدارة الأقسام
// ------------------------------------------------------------------
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final TextEditingController _classController = TextEditingController();

  void _addClass() {
    if (_classController.text.isNotEmpty) {
      setState(() {
        SchoolData.classes.add(SchoolClass(name: _classController.text, students: []));
        _classController.clear();
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('${SchoolData.subjectName} - الأقسام'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
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
                );
              },
            ),
          );
        },
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

// ------------------------------------------------------------------
// الشاشة الرابعة: واجهة التلاميذ المتقدمة داخل القسم
// ------------------------------------------------------------------
class StudentsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const StudentsScreen({super.key, required this.schoolClass});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  // فرز أبجدي
  void _sortAlphabetically() {
    setState(() {
      widget.schoolClass.students.sort((a, b) => a.lastName.compareTo(b.lastName));
    });
  }

  // إضافة أو تعديل تلميذ
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
            onPressed: () {
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
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // نافذة تعديل النقاط مع السبب
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
            onPressed: () {
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
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  // سجل التلميذ التاريخي
  void _showStudentHistory(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سجل المتابعة: ${student.lastName} ${student.firstName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: student.logs.isEmpty
              const Center(child: Text('لا توجد سجلات مسجلة بعد'))
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.schoolClass.name),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: 'ترتيب أبجدي',
            onPressed: _sortAlphabetically,
          ),
        ],
      ),
      body: widget.schoolClass.students.isEmpty
          const Center(child: Text('لا يوجد تلاميذ مسجلين في هذا القسم. اضغط على زر الإضافة.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.schoolClass.students.length,
              itemBuilder: (context, index) {
                final student = widget.schoolClass.students[index];
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
                            // خيارات الحالة (حاضر، غائب، هارب، إذن)
                            DropdownButton<String>(
                              value: student.status,
                              items: ['حاضر', 'غائب', 'هرب', 'خروج بإذن'].map((status) {
                                return DropdownMenuItem(value: status, child: Text(status, style: TextStyle(
                                  color: status == 'حاضر' ? Colors.green : (status == 'غائب' ? Colors.red : Colors.orange),
                                  fontWeight: FontWeight.bold,
                                )));
                              }).onChanged: (val) {
                                setState(() {
                                  student.status = val!;
                                  if (val == 'خروج بإذن' || val == 'هرب') {
                                    student.exitTime = TimeOfDay.now().format(context);
                                    student.logs.add(BehaviorLog(description: 'تغيير الحالة إلى: $val', pointsChange: 0, time: student.exitTime!));
                                  }
                                });
                              },
                            ),
                            // النقاط والسجل
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
