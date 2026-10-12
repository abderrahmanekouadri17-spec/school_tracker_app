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
      title: 'إدارة الحضور والنقاط',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StudentsHomePage(),
    );
  }
}

class Student {
  String name;
  bool isPresent;
  int points;

  Student({required this.name, this.isPresent = true, this.points = 0});
}

class StudentsHomePage extends StatefulWidget {
  const StudentsHomePage({super.key});

  @override
  State<StudentsHomePage> createState() => _StudentsHomePageState();
}

class _StudentsHomePageState extends State<StudentsHomePage> {
  final List<Student> _students = [
    Student(name: 'أحمد محمد', points: 5),
    Student(name: 'فاطمة علي', points: 8),
    Student(name: 'يوسف إبراهيم', points: 3),
  ];

  final TextEditingController _controller = TextEditingController();

  void _addStudent() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _students.add(Student(name: _controller.text));
        _controller.clear();
      });
      Navigator.pop(context);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة تلميذ جديد'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: 'اكتب اسم التلميذ هنا'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _addStudent,
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تطبيق إدارة الحضور ونقاط السلوك'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Text('النقاط: ${student.points}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (student.points > 0) student.points--;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        student.points++;
                      });
                    },
                  ),
                  Switch(
                    value: student.isPresent,
                    onChanged: (value) {
                      setState(() {
                        student.isPresent = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
