import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic>? profileData;
  final TextEditingController mgSearchController = TextEditingController();
  String? selectedStageForList;

  final List<String> allStages = [
    'Ideation',
    'Idea Validation',
    'Prototype',
    'Early Traction Stage',
    'Scale Up Stage',
    'Expansion Stage',
    'Completed Your Journey',
  ];

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchProfile();
  }

  Future<void> fetchStudents() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      setState(() {
        students = snapshot.docs
            .map((doc) => doc.data())
            .where((user) => (user['role'] ?? 'student') == 'student')
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching students: $e');
    }
  }

  Future<void> fetchProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() => profileData = doc.data());
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  List<Map<String, dynamic>> get filteredStudents {
    final query = mgSearchController.text.toLowerCase().trim();
    if (query.isEmpty) return students;
    return students.where((s) =>
        s['mgid']?.toString().toLowerCase().contains(query) ?? false).toList();
  }

  Map<String, int> get stageCounts {
    final Map<String, int> counts = {for (var s in allStages) s: 0};
    for (var student in students) {
      final stage = student['stage'] ?? '';
      if (counts.containsKey(stage)) {
        counts[stage] = (counts[stage] ?? 0) + 1;
      }
    }
    return counts;
  }
List<Map<String, dynamic>> studentsInStage(String stage) {
  return students.where((s) => s['stage'] == stage).toList();
}

  // ignore: unused_element
  void _showStudentsInStage(String stage) =>
      setState(() => selectedStageForList = stage);
  void _closeStageList() => setState(() => selectedStageForList = null);

  Future<void> _showStudentProfile(Map<String, dynamic> student) async {
    String description = 'No verified submissions found.';
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('stage_submissions')
          .where('uid', isEqualTo: student['uid'])
          .where('verified', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        description = data['description'] ?? description;
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF232323),
        title: Text(student['name'], style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MG: ${student['mgid']}', style: const TextStyle(color: Colors.white70)),
            Text('Stage: ${student['stage']}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

void _showProfileSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // 👈 Important for full height sheets
    backgroundColor: const Color(0xFF1E1E1E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => profileData == null
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        : SizedBox(
            height: MediaQuery.of(context).size.height * 0.6, // 👈 Bigger height
            width: MediaQuery.of(context).size.width * 0.95,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    "My Profile",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 50, // 👈 Bigger avatar
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      (profileData!['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileData!['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Role: ${profileData!['role'] ?? 'N/A'}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "MG ID: ${profileData!['mgid'] ?? ''}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showChangePasswordDialog();
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text("Change Password"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}


  void _showChangePasswordDialog() {
    final TextEditingController emailController = TextEditingController(text: FirebaseAuth.instance.currentUser?.email);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("A password reset link will be sent to your email."),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reset link sent")));
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send reset email")));
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Director Dashboard"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: _showProfileSheet),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Student Progress Overview", style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: allStages.map((stage) {
                  final count = stageCounts[stage] ?? 0;
                  return PieChartSectionData(
                    color: Colors.primaries[allStages.indexOf(stage) % Colors.primaries.length],
                    value: count > 0 ? count.toDouble() : 0.1,
                    title: count.toString(),
                    radius: stage == selectedStageForList ? 60 : 50,
                    titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: allStages.map((stage) {
              final color = Colors.primaries[allStages.indexOf(stage) % Colors.primaries.length];
              final count = stageCounts[stage] ?? 0;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$stage ($count)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (selectedStageForList != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Students in "$selectedStageForList"',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: _closeStageList),
              ],
            ),
            ...studentsInStage(selectedStageForList!).map((student) => ListTile(
                  title: Text(student['name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text('MG: ${student['mgid']}', style: const TextStyle(color: Colors.white70)),
                  trailing: ElevatedButton(
                    onPressed: () => _showStudentProfile(student),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text('View', style: TextStyle(color: Colors.white)),
                  ),
                )),
          ],
          const SizedBox(height: 20),
          const Text('Search by MG ID', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: mgSearchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter MG ID',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black87,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                mgSearchController.clear();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Clear", style: TextStyle(color: Colors.white)),
            )
          ]),
          const SizedBox(height: 20),
          const Text('Student List', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 10),
          ListView.separated(
            itemCount: filteredStudents.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return ListTile(
                title: Text(student['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('MG: ${student['mgid']} | Stage: ${student['stage']}',
                    style: const TextStyle(color: Colors.white70)),
                trailing: ElevatedButton(
                  onPressed: () => _showStudentProfile(student),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text("View", style: TextStyle(color: Colors.white)),
                ),
              );
            },
          )
        ]),
      ),
    );
  }
}
