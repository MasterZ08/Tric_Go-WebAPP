import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:sub_admin_panel/dashboard/TODA_Panel/COSDOM_Panel.dart';
import 'package:sub_admin_panel/dashboard/TODA_Panel/LTODA_Panel.dart';
import 'package:sub_admin_panel/dashboard/TODA_Panel/SATODA_Panel.dart';
import 'package:sub_admin_panel/dashboard/TODA_Panel/STMJ_Panel.dart';
import 'package:sub_admin_panel/dashboard/Sub_Admin_Panel.dart';
import 'package:sub_admin_panel/methods/common_methods.dart';
import 'package:sub_admin_panel/widgets/loading_dialog.dart';
import '../dashboard/Admin Panel Permissions/Access 2.dart';
import '../dashboard/Admin Panel Permissions/Access 3.dart';
import '../dashboard/Admin Panel Permissions/Access 4.dart';
import '../dashboard/Admin Panel Permissions/Admin_Panel.dart';
import 'package:flutter/services.dart';

import '../dashboard/Admin Panel Permissions/Super_Admin_Panel.dart';

// Custom TextInputFormatter to prevent pasting
class NoPasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Allow all changes if the length of the text does not change significantly
    if (newValue.text.length <= oldValue.text.length) {
      return newValue;
    }

    // Allow autofill and suggestions (not paste operations)
    if (newValue.text.length - oldValue.text.length <= 1) {
      return newValue;
    }

    // If the new text is significantly longer, it is likely a paste operation
    return oldValue; // Prevent pasting
  }
}

//activity log
class ActivityLogger {
  final DatabaseReference _activityLogRef = FirebaseDatabase.instance.ref().child("activity_logs");

  Future<void> logActivity(String userId, String activity, String name, String email, String role) async {
    final timestamp = DateTime.now().toIso8601String();
    final newActivity = {
      'timestamp': timestamp,
      'userId': userId,
      'activity': activity,
      'name': name,
      'email': email,
      'role': role,
    };

    await _activityLogRef.push().set(newActivity);
  }
}

class Authentication extends StatefulWidget {
  const Authentication({Key? key}) : super(key: key);

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  bool _passwordVisible = false;

  // Attempt
  bool _isLockedOut = false;
  int _loginAttempts = 0;
  late Timer _lockoutTimer;
  Duration _remainingLockoutTime = Duration.zero;

  final int _maxAttempts = 5;
  final Duration _lockoutDuration = Duration(seconds: 30);
  ActivityLogger activityLogger = ActivityLogger(); // Initialize the ActivityLogger

  CommonMethods cMethods = CommonMethods();
  FocusNode _focusNode = FocusNode();

  void _showLockoutDialog() {
    showDialog(
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
              maxHeight: 300,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.lock_outline,
                  size: 50,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Too Many Attempts",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'You have been locked out due to too many failed login attempts. Please try again in ${_remainingLockoutTime.inSeconds} seconds.',
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

  void _startLockoutTimer() {
    setState(() {
      _isLockedOut = true;
      _remainingLockoutTime = _lockoutDuration;
    });

    _lockoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingLockoutTime > Duration.zero) {
          _remainingLockoutTime -= Duration(seconds: 1);
        } else {
          _isLockedOut = false;
          _loginAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  void checkIfNetworkIsAvailable() {
    if (_isLockedOut) {
      _showLockoutDialog();
      return;
    }
    signInFormValidation();
  }

  void signInFormValidation() {
    if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please enter a valid email address.", context);
    } else if (passwordTextEditingController.text.trim().length < 6) {
      cMethods.displaySnackBar("Password must be 6 or more characters.", context);
    } else {
      signInUser();
    }
  }

  void signInUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Logging in..."),
    );

    final User? userFirebase = (
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          password: passwordTextEditingController.text.trim(),
        ).catchError((errorMsg) {
          Navigator.pop(context);
          _showErrorDialog("Wrong Email or Password. Please Try Again.");
          setState(() {
            _loginAttempts++;
            if (_loginAttempts >= _maxAttempts) {
              _startLockoutTimer();
            }
          });
        })
    ).user;

    if (!context.mounted) return;
    Navigator.pop(context);

    if (userFirebase != null) {
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("accounts").child(userFirebase.uid);
      usersRef.once().then((snap) async {
        if (snap.snapshot.value != null) {
          Map userData = snap.snapshot.value as Map;
          if (userData["blockStatus"] == "no") {
            String userRole = userData["role"];
            await Future.delayed(const Duration(seconds: 2)); // Simulate loading delay

            if (userRole == "Admin") {
              // Log the activity for admin only
              String role = userData["role"] ?? "Unknown";
              String name = userData["name"] ?? "Unknown";
              String email = userData["email"] ?? "Unknown";
              await activityLogger.logActivity(userFirebase.uid, "Logged in", name, email, role);

              // Proceed to check access
              String userfeatures = userData["access"];
              switch (userfeatures) {
                case "Super Admin": // Access to All
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const Super_Admin_Panel()));
                  break;
                case "Access #1": // Access to All
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const Admin_Panel()));
                  break;
                case "Access #2": // Add, Update, Delete Admin only
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const Admin_Panel_Access_2()));
                  break;
                case "Access #3": // Add, Update, Delete Sub Admin only
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const Admin_Panel_Access_3()));
                  break;
                case "Access #4": // Viewing and Searching Purpose only
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const Admin_Panel_Access_4()));
                  break;
                default:
                  _showErrorDialog("Invalid access. Contact Admin.");
                  break;
              }
            } else if (userRole == "Sub-Admin") {
              // Skip logging activity for sub-admins
              String userToda = userData["toda"];
              switch (userToda) {
                case "COSDOMTODA":
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const COSDOM_Panel()));
                  break;
                case "LTODA":
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LTODA_Panel()));
                  break;
                case "SATODA":
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SATODA_Panel()));
                  break;
                case "STMJDTODA":
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const STMJD_Panel()));
                  break;
                default:
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Sub_Admin_Panel()));
                  break;
              }
            } else {
              _showErrorDialog("Invalid role. Contact Admin.");
            }
          } else {
            FirebaseAuth.instance.signOut();
            _showErrorDialog("You are blocked. Contact Admin: zivenpaule@gmail.com");
          }
        } else {
          FirebaseAuth.instance.signOut();
          _showErrorDialog("No record found. Contact Admin: zivenpaule@gmail.com");
        }
      });
    } else {
      _showErrorDialog("Something went wrong. Contact Admin: zivenpaule@gmail.com");
    }
  }

  void _showErrorDialog(String message) {
    setState(() {
      passwordTextEditingController.clear(); // Clear the password field
    });

    showDialog(
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
  //function for forget password
  void _resetPassword() async {
    String email = emailTextEditingController.text.trim();
    if (email.isEmpty) {
      cMethods.displaySnackBar("Please enter your email address.", context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          LoadingDialog(messageText: "Sending password reset email..."),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Navigator.pop(context);
      _showResetPasswordSuccessDialog();
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog("Failed to send password reset email. Please check your email address.");
    }
  }
  //reset success
  void _showResetPasswordSuccessDialog() {
    showDialog(
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
                  Icons.check_circle_outline,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Password Reset Email Sent",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please check your email for instructions to reset your password.',
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

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent.withOpacity(0.5), // Set Scaffold background to transparent
      body: RawKeyboardListener(
        focusNode: _focusNode,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              checkIfNetworkIsAvailable();
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blueAccent.withOpacity(0.5),
                Colors.lightBlueAccent.withOpacity(0.5), // Adjust colors as per your preference
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.grey.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome to the Tric GO: Web Panel Application",
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: emailTextEditingController,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [NoPasteFormatter()],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.email, color: Colors.white),
                              labelText: "Email",
                              labelStyle: const TextStyle(color: Colors.white),
                              hintText: "Enter your email",
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                            ),

                            enabled: !_isLockedOut, // Disable if locked out
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: passwordTextEditingController,
                            obscureText: !_passwordVisible,
                            inputFormatters: [NoPasteFormatter()],
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: Colors.white),
                              labelText: "Password",
                              labelStyle: const TextStyle(color: Colors.white),
                              hintText: "Enter your password",
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                              ),
                            ),
                            enabled: !_isLockedOut, // Disable if locked out
                          ),

                          const SizedBox(height: 30),
                          if (_isLockedOut)
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock, // Change to the icon you prefer
                                    color: Colors.grey,
                                    size: 30, // Adjust the size as needed
                                  ),
                                  SizedBox(width: 10), // Space between the icon and the text
                                  Text(
                                    'Locked out. Try again in ${_remainingLockoutTime.inSeconds} seconds.',
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 30),
                          Center(
                            child: SizedBox(
                              width: 150,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: checkIfNetworkIsAvailable,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          //FORGOT PASSWORD BUTTON
                          const SizedBox(height: 20),
                     /*     Center(
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ), */
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        "images/FINAL LOGO.png",
                        fit: BoxFit.cover,
                      ),
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
