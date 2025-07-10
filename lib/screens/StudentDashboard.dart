// === student_dashboard.dart ===

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  String studentName = '';
  int currentStage = 0;
  String? uid;
  Map<String, dynamic> pendingSubmissions = {};
  late AnimationController _controller;

  final List<String> stages = [
    'Ideation',
    'Idea Validation',
    'Prototype',
    'Early Traction Stage',
    'Scale Up Stage',
    'Expansion Stage',
    'Completed Your Journey',
  ];

  double get progressPercent =>
      (currentStage / (stages.length - 1)).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _listenToStageUpdates();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _listenToStageUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              studentName = data['name'] ?? 'Student';
              currentStage = _getStageIndex(data['stage'] ?? 'Ideation');
              if (currentStage == stages.length - 1) {
                _controller.forward();
              }
            });
            _checkPendingSubmission();
          }
        }
      });
    }
  }

  int _getStageIndex(String stageName) {
    final index = stages.indexOf(stageName);
    return index == -1 ? 0 : index;
  }

  void _checkPendingSubmission() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stage_submissions')
        .where('student', isEqualTo: studentName)
        .get();

    final Map<String, dynamic> pending = {};
    for (var doc in snapshot.docs) {
      final isRejected = doc['rejected'] == true;
      final isVerified = doc['verified'] == true;
      pending[doc['stage']] = isVerified ? 'verified' : (isRejected ? 'rejected' : true);
    }

    setState(() {
      pendingSubmissions = pending;
    });
  }

  void _openSubmissionSheet(String stageTitle) {
    final TextEditingController descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit for "$stageTitle"',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[850],
                  hintText: 'Describe your work...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (descController.text.trim().isEmpty) return;

                    await FirebaseFirestore.instance
                        .collection('stage_submissions')
                        .add({
                      'student': studentName,
                      'uid': uid,
                      'stage': stageTitle,
                      'description': descController.text.trim(),
                      'timestamp': FieldValue.serverTimestamp(),
                      'verified': false,
                      'rejected': false,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Submitted! Please wait for admin verification.",
                        ),
                      ),
                    );
                    _checkPendingSubmission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Submit"),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _onStageTap(int index) {
    final status = pendingSubmissions[stages[index]];
    final isPending = status == true;
    final isRejected = status == 'rejected';

    if (index != currentStage || (!isRejected && isPending)) return;
    if (stages[index] == 'Completed Your Journey') return;
    _openSubmissionSheet(stages[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentStage == stages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_sharp),
            onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progressPercent,
                    strokeWidth: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                ),
                isCompleted
                    ? ScaleTransition(
                        scale: Tween(begin: 0.7, end: 1.2).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 36,
                        ),
                      )
                    : Text(
                        '${(progressPercent * 100).toInt()}%',
                        style: const TextStyle(fontSize: 22, color: Colors.white),
                      ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final status = pendingSubmissions[stages[index]];
                  return GestureDetector(
                    onTap: () => _onStageTap(index),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < currentStage
                                    ? Colors.green
                                    : index == currentStage
                                        ? Colors.blueAccent
                                        : Colors.grey,
                              ),
                            ),
                            if (index != stages.length - 1)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                width: 2,
                                height: 40,
                                color: (index < currentStage || index == currentStage - 1)
                                    ? Colors.green
                                    : index == currentStage
                                        ? Colors.blueAccent
                                        : Colors.white24,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: index <= currentStage
                                  ? Colors.blueGrey[800]
                                  : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  stages[index],
                                  style: TextStyle(
                                    color: index <= currentStage ? Colors.white : Colors.white38,
                                    fontWeight: index == currentStage
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (status == true)
                                  const Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 12,
                                    ),
                                  )
                                else if (status == 'rejected')
                                  const Text(
                                    'Rejected - Resubmit',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  )
                                else if (status == 'verified')
                                  const Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
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