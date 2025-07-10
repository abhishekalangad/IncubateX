import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  List<Map<String, dynamic>> mentees = [];
  final TextEditingController nameSearchController = TextEditingController();
  Map<String, dynamic>? profileData;

  final List<String> stages = [
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
    fetchMentorAndMentees();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          profileData = doc.data();
        });
      }
    }
  }

  Future<void> fetchMentorAndMentees() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final mentorDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mentorDoc.exists) return;

      final mentorMgid = mentorDoc.data()?['mgid'];
      if (mentorMgid == null) return;

      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('mgid', isEqualTo: mentorMgid)
              .get();

      setState(() {
        mentees =
            studentsSnapshot.docs
                .map((doc) => doc.data())
                .toList();
      });
    } catch (e) {
      debugPrint('Error fetching mentor or students: $e');
    }
  }

  List<Map<String, dynamic>> get filteredMentees {
    final query = nameSearchController.text.toLowerCase().trim();
    if (query.isEmpty) return mentees;
    return mentees
        .where(
          (m) => m['name']?.toString().toLowerCase().contains(query) ?? false,
        )
        .toList();
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            height:
                MediaQuery.of(context).size.height * 0.6, // 👈 Bigger height
            width: MediaQuery.of(context).size.width * 0.95,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child:
                profileData == null
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text(
                            "My Profile",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              (profileData!['name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profileData!['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            "Role: ${profileData!['role'] ?? 'N/A'}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "MG ID: ${profileData!['mgid'] ?? ''}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            profileData!['email'] ?? '',
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
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _logout();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text("Logout"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController emailController = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.email,
    );
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: emailController.text.trim(),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Reset link sent")),
                    );
                  } catch (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to send reset email"),
                      ),
                    );
                  }
                },
                child: const Text("Send"),
              ),
            ],
          ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
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

  Widget _buildStageChip(String stage) {
    Color color;
    switch (stage) {
      case 'Ideation':
        color = Colors.orange;
        break;
      case 'Idea Validation':
        color = Colors.blueGrey;
        break;
      case 'Prototype':
        color = Colors.teal;
        break;
      case 'Early Traction Stage':
        color = Colors.indigo;
        break;
      case 'Scale Up Stage':
        color = Colors.purple;
        break;
      case 'Expansion Stage':
        color = Colors.deepPurple;
        break;
      case 'Completed Your Journey':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(
        stage,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text("Mentor Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _showProfileSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Mentees",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameSearchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black87,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    nameSearchController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  filteredMentees.isEmpty
                      ? const Center(
                        child: Text(
                          "No mentees found.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredMentees.length,
                        itemBuilder: (context, index) {
                          final student = filteredMentees[index];
                          return Card(
                            color: Colors.blueGrey[900],
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.white70,
                              ),
                              title: Text(
                                student['name'] ?? 'Unnamed',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'MG: ${student['mgid']}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: _buildStageChip(
                                student['stage'] ?? 'Not Available',
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
