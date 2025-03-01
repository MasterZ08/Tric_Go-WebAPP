import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sub_admin_panel/widgets/act_log_current_user.dart';
import 'package:sub_admin_panel/pages/profile_overview.dart'; // Import the shimmer package

void main() {
  runApp(AccountPage());
}

class AccountPage extends StatefulWidget {
  static const String Id = "/webpageAccountPage";

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? profileImageUrl;
  String _userName = '';
  String _phoneNumber = '';
  String _TODA = '';
  String _email = '';

  String _oldPassword = '';
  String _newPassword = '';
  String _reEnterNewPassword = '';
  bool _isLoading = true;
  bool obscurePassword = true;
  bool hasMinLength = false;
  bool hasUpperCase = false;
  bool hasSpecialChar = false;
  bool passwordsMatch = false;
  bool _isPasswordCorrect = true;
  bool isFormValid = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref('accounts');

  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _reEnterNewPasswordController;


  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _reEnterNewPasswordController = TextEditingController();

  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _reEnterNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.check_circle,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password updated successfully!',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _oldPasswordController.clear();
                      _newPasswordController.clear();
                      _reEnterNewPasswordController.clear();
                      _oldPassword = '';
                      _newPassword = '';
                      _reEnterNewPassword = '';
                      _isPasswordCorrect = true;
                      hasMinLength = false;
                      hasUpperCase = false;
                      hasSpecialChar = false;
                      passwordsMatch = false;
                      isFormValid = false;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changePassword() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && _oldPassword.isNotEmpty && _newPassword.isNotEmpty &&
          _reEnterNewPassword.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: _oldPassword);

        try {
          await user.reauthenticateWithCredential(credential);
          if (_newPassword == _reEnterNewPassword && hasMinLength &&
              hasUpperCase && hasSpecialChar) {
            await user.updatePassword(_newPassword);
            await _showSuccessDialog();
          } else {
            await _showErrorDialog(
                'New passwords do not match or do not meet requirements');
          }
        } catch (e) {
          setState(() {
            _isPasswordCorrect = false;
          });
          await _showErrorDialog('You inputted a wrong old password');
        }
      } else {
        await _showErrorDialog('Please fill all the fields');
      }
    } catch (e) {
      await _showErrorDialog('Error updating password: $e');
    }
  }

  void validatePassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8 && value.length <= 20;
      hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_]'));
      isFormValid =
          hasMinLength && hasUpperCase && hasSpecialChar && passwordsMatch;
    });
  }

  void checkPasswordsMatch(String value) {
    setState(() {
      passwordsMatch = _newPassword == value;
      isFormValid =
          hasMinLength && hasUpperCase && hasSpecialChar && passwordsMatch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey.shade50, Colors.blueGrey.shade100],
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Center(
                        child: const Text(
                        "Profile Page",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.info_outline),
                          iconSize: 20,
                          color: Colors.black,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                  content: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 400,
                                      maxHeight: 300,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(
                                          child: const Text(
                                            'Information',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Center(
                                          child: const Text(
                                            'Log Activity records will automatically be deleted after 30 days.',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                            ),
                                            child: const Text(
                                              "OK",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    ],
                  )
                ),
                const SizedBox(height: 16), // Space under the title
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Profile Overview Section
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: Colors.blueAccent,
                            child: Profile_Overview(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}