// === submission_requests_page.dart ===

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionRequestsPage extends StatelessWidget {
  const SubmissionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Student Stage Submissions"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stage_submissions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No submissions yet.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final submissions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              final data = submissions[index].data() as Map<String, dynamic>;
              final docId = submissions[index].id;
              final student = data['student'] ?? 'Unknown';
              final stage = data['stage'] ?? 'Unknown Stage';
              final description = data['description'] ?? '';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                color: Colors.blueGrey[900],
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubmissionDetailPage(
                            data: data,
                            docId: docId,
                          ),
                        ),
                      );
                    },
                    leading: const Icon(Icons.assignment, color: Colors.white),
                    title: Text(
                      '$student → $stage',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timestamp != null
                              ? 'Submitted: ${timestamp.toLocal().toString().split('.')[0]}'
                              : 'No timestamp',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SubmissionDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const SubmissionDetailPage({
    super.key,
    required this.data,
    required this.docId,
  });

  @override
  State<SubmissionDetailPage> createState() => _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends State<SubmissionDetailPage> {
  String? selectedStage;

  final List<String> stageList = [
    'Ideation',
    'Idea Validation',
    'Prototype',
    'Early Traction Stage',
    'Scale Up Stage',
    'Expansion Stage',
    'Completed Your Journey',
  ];

  Future<void> _verifySubmission(BuildContext context) async {
    final userRef = FirebaseFirestore.instance.collection('users');
    final submissionsRef = FirebaseFirestore.instance.collection('stage_submissions');

    try {
      final userSnapshot = await userRef.where('name', isEqualTo: widget.data['student']).get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student not found')),
        );
        return;
      }

      final userDoc = userSnapshot.docs.first;

      if (selectedStage != null && selectedStage!.isNotEmpty) {
        await userRef.doc(userDoc.id).update({'stage': selectedStage});
      }

      await submissionsRef.doc(widget.docId).update({
        'verified': true,
        'rejected': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission verified & stage updated')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _rejectSubmission(BuildContext context) async {
    final submissionsRef = FirebaseFirestore.instance.collection('stage_submissions');

    try {
      await submissionsRef.doc(widget.docId).update({
        'rejected': true,
        'verified': false,
        'rejection_note': 'Please improve your submission and try again.',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission rejected and student notified')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.data['student'] ?? 'Unknown';
    final stage = widget.data['stage'] ?? 'Unknown';
    final description = widget.data['description'] ?? '';
    final timestamp = (widget.data['timestamp'] as Timestamp?)?.toDate();
    final verified = widget.data['verified'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Submission Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$student → $stage",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text("Description:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            if (timestamp != null)
              Text(
                "Submitted: ${timestamp.toLocal().toString().split('.')[0]}",
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 30),
            if (!verified) ...[
              DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[900],
                value: selectedStage,
                hint: const Text(
                  'Select stage to assign',
                  style: TextStyle(color: Colors.white70),
                ),
                items: stageList
                    .map(
                      (stage) => DropdownMenuItem(
                        value: stage,
                        child: Text(
                          stage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedStage = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _verifySubmission(context),
                icon: const Icon(Icons.check),
                label: const Text("Verify & Update Stage"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _rejectSubmission(context),
                icon: const Icon(Icons.cancel),
                label: const Text("Reject Submission"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ] else
              const Text(
                "Status: Verified ✅",
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
