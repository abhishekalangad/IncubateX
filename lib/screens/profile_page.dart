import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? _selectedOption;
  bool? _ideaOptionVerified;
  File? _imageFile;

  final List<String> _ideaOptions = [
    'With Idea',
    'Without Idea',
    'Upscale Existing Business',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          _selectedOption = userData?['ideaOption'];
          _ideaOptionVerified = userData?['ideaOptionVerified'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
      // TODO: Optional — Upload to Firebase Storage and save URL
    }
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'ideaOption': _selectedOption,
        'ideaOptionVerified': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    }
  }
  Widget _passwordField(String label, TextEditingController controller) {
  return TextField(
    controller: controller,
    obscureText: true,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black54,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

void _showSnack(String msg, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color),
  );
}

  void _showChangePasswordDialog() {
  final currentPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF232323),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField("Current Password", currentPassController),
              const SizedBox(height: 12),
              _passwordField("New Password", newPassController),
              const SizedBox(height: 12),
              _passwordField("Confirm New Password", confirmPassController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () async {
              final current = currentPassController.text.trim();
              final newPass = newPassController.text.trim();
              final confirm = confirmPassController.text.trim();

              if (newPass != confirm) {
                _showSnack("New passwords do not match", Colors.redAccent);
                return;
              }
              if (newPass.length < 6) {
                _showSnack("Password must be at least 6 characters", Colors.redAccent);
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                final cred = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: current,
                );

                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newPass);
                Navigator.pop(context);
                _showSnack("Password changed successfully", Colors.green);
              } catch (e) {
                Navigator.pop(context);
                _showSnack("Error: ${e.toString()}", Colors.redAccent);
              }
            },
            child: const Text('Change', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/student_dashboard');
          },
        ),
        title: const Text("My Profile"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text("User data not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : const AssetImage('assets/default_avatar.png') as ImageProvider,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color.fromARGB(255, 9, 9, 9),
                              child: const Icon(Icons.edit, size: 18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userData!['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (userData!['isVerified'] == true)
                            const Icon(
                              Icons.verified,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        userData!['email'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "MG ID: ${userData!['mgid'] ?? ''}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("What best describes your status?"),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedOption,
                            items: _ideaOptions
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: const Color.fromARGB(255, 12, 12, 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedOption = value;
                                _ideaOptionVerified = false;
                              });
                            },
                          ),
                          if (_ideaOptionVerified == true)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Verified by Admin",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.blueGrey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text(
                                "Startup Journey Stage",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                userData!['stage'] ?? 'Not Started',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (userData!['createdAt'] != null)
                        Text(
                          "Joined on: ${userData!['createdAt'].toDate().toLocal().toString().split(' ')[0]}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Changes"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
ElevatedButton.icon(
  onPressed: _showChangePasswordDialog,
  icon: const Icon(Icons.lock_outline),
  label: const Text("Change Password"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.deepOrangeAccent,
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
  ),
),
const SizedBox(height: 20),

                    ],
                  ),
                ),
    );
  }
}
