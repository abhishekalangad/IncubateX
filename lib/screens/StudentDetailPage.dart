import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailPage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const StudentDetailPage({super.key, required this.uid, required this.data});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Map<String, dynamic> student;

  final List<String> stages = [
    'Registered',
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
    student = {
      ...widget.data,
      'stage': widget.data['stage'] ?? 'Registered',
    };
  }

  Future<void> _toggleVerification() async {
    final newStatus = !(student['isVerified'] ?? false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(newStatus ? 'Verify Student' : 'Unverify Student'),
        content: Text(
          newStatus
              ? 'Are you sure you want to verify this student?'
              : 'Are you sure you want to unverify this student?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'isVerified': newStatus,
      });
      setState(() {
        student['isVerified'] = newStatus;
      });
    }
  }

  Future<void> _confirmStage(String stage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Stage Update'),
        content: Text('Are you sure you want to set stage to "$stage"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'stage': stage,
      });
      setState(() {
        student['stage'] = stage;
      });
    }
  }

  Future<void> _verifyIdeaOption() async {
    String selectedStage = 'Ideation';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Verify Idea Option & Assign Stage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Idea Option: ${student['ideaOption']}'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStage,
                    items: stages
                        .where((stage) => stage != 'Registered')
                        .map((stage) => DropdownMenuItem(
                              value: stage,
                              child: Text(stage),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedStage = value;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Select starting stage",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Verify")),
              ],
            );
          },
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'ideaOptionVerified': true,
        'stage': selectedStage,
      });
      setState(() {
        student['ideaOptionVerified'] = true;
        student['stage'] = selectedStage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Idea option verified. Stage set to '$selectedStage'")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = student['stage'] ?? 'Registered';
    final ideaOption = student['ideaOption'] ?? 'Not selected';
    final isIdeaVerified = student['ideaOptionVerified'] ?? false;

    return Scaffold(
      appBar: AppBar(title: Text("Student: ${student['name']}")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text("Name: ${student['name']}", style: const TextStyle(fontSize: 18)),
            Text("Email: ${student['email']}"),
            Text("MG ID: ${student['mgid']}"),
            const SizedBox(height: 20),

            /// 🔐 Account verification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Verified: ${student['isVerified'] == true ? "Yes" : "No"}",
                  style: const TextStyle(fontSize: 16),
                ),
                ElevatedButton(
                  onPressed: _toggleVerification,
                  child: Text(student['isVerified'] == true ? 'Unverify' : 'Verify'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// 🚀 Startup Stage
            Text("Current Stage: $currentStage", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stages.map((stage) {
                return ElevatedButton(
                  onPressed: () => _confirmStage(stage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stage == currentStage ? Colors.green : Colors.blueGrey,
                  ),
                  child: Text(stage),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            /// 💡 Idea Option Verification
            Text("Idea Option: $ideaOption", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            if (!isIdeaVerified && ideaOption != 'Not selected')
              ElevatedButton.icon(
                onPressed: _verifyIdeaOption,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Verify Idea Option & Assign Stage"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              )
            else if (isIdeaVerified)
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 6),
                  Text("Idea Option Verified", style: TextStyle(color: Colors.green)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
