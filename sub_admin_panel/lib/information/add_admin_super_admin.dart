//Super Admin Access
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:shimmer/shimmer.dart';
import '../dashboard/Admin Panel Permissions/Super_Admin_Panel.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';
import 'package:flutter/services.dart';

class Add_Admin_Super_Admin extends StatefulWidget {
  const Add_Admin_Super_Admin({Key? key}) : super(key: key);

  @override
  State<Add_Admin_Super_Admin> createState() => _Add_Admin_Super_AdminState();
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

class _Add_Admin_Super_AdminState extends State<Add_Admin_Super_Admin> {
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailUsernameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  String selectedRole = 'Admin';
  String? selectedAccess;

  // String? selectedCoding;

  //password Requirements
  bool obscurePassword = true;
  bool hasMinLength = false;
  bool hasUpperCase = false;
  bool hasSpecialChar = false;

  bool showConfirmationSnackbar = false; // Track if confirmation snackbar is shown

  bool get isFormValid {
    return nameTextEditingController.text.trim().isNotEmpty &&
        emailUsernameTextEditingController.text.trim().isNotEmpty &&
        phoneTextEditingController.text.trim().isNotEmpty &&
        passwordTextEditingController.text.trim().isNotEmpty &&
        selectedAccess != null &&
        hasMinLength &&
        hasUpperCase &&
        hasSpecialChar;
  }

  checkIfNetworkIsAvailable() {
    signUpFormValidation();
    if (isFormValid) {
      // Only proceed if the form is valid
      registerNewUser();
    }
  }


  signUpFormValidation() {
    if (nameTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar(
        "Please enter a name for the admin.",
        context,
      );
    } else if (emailUsernameTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar(
        "Please enter a valid email address.",
        context,
      );
    } else if (!RegExp(r'^09\d{9}$')
        .hasMatch(phoneTextEditingController.text.trim())) {
      cMethods.displaySnackBar(
        "Phone number must be a valid 11-digit Philippine number starting with 09.",
        context,
      );
    } else if (!hasMinLength ||
        !hasUpperCase ||
        !hasSpecialChar) {
      cMethods.displaySnackBar(
        "Password must be 8-20 characters, contain an uppercase letter, and include at least one special character.",
        context,
      );
    } //else if (selectedCoding == null) {
    // cMethods.displaySnackBar("Please select a Day of your Coding.", context);
    // if walang piniling day

    else if (selectedAccess == null) {
      cMethods.displaySnackBar(
        "Please select an access level.",
        context,
      );
    } else {

      // Show confirmation snackbar with input data
      setState(() {
        showConfirmationSnackbar = true;
      });
    }
  }


  registerNewUser() async {
    // Store current user credentials
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentEmail = currentUser?.email ?? '';
    String currentPassword = passwordTextEditingController.text.trim(); // You may need to handle storing and getting the current user's password securely
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(
        messageText: "Registering new Admin...",
      ),
    );

    try {
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailUsernameTextEditingController.text.trim() + "@tric.go",
        password: passwordTextEditingController.text.trim(),
      );

      final User? userFirebase = userCredential.user;

      if (userFirebase != null) {
        DatabaseReference accountsRef = FirebaseDatabase.instance
            .reference()
            .child("accounts")
            .child(userFirebase.uid);

        Map<String, dynamic> userDataMap = {
          "name": nameTextEditingController.text.trim(),
          "email": emailUsernameTextEditingController.text.trim() + "@tric.go",
          "phone": phoneTextEditingController.text.trim(),
          "id": userFirebase.uid,
          "role": selectedRole,
          "blockStatus": "no",
          "access": selectedAccess,
          // Add other fields if needed
        };
        await accountsRef.set(userDataMap);

        // Re-authenticate the current user
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: currentEmail,
          password: currentPassword,
        );

        // Dismiss loading dialog
        Navigator.of(context).pop();

        // Show success dialog
        showSuccessDialog(
          context,
          userFirebase.uid,
          nameTextEditingController.text.trim(),
          emailUsernameTextEditingController.text.trim() + "@tric.go",
          selectedRole,
        );
      }
    } catch (error) {
      Navigator.of(context).pop(); // Dismiss loading dialog
      cMethods.displaySnackBar(error.toString(), context);
    }
  }


  Future<void> showSuccessDialog(BuildContext context, String userId, String name, String email, String role) async {

    // Get current admin's details
    User? currentUser = FirebaseAuth.instance.currentUser;
    String currentAdminUserId = currentUser?.uid ?? 'unknown';
    String currentAdminEmail = currentUser?.email ?? 'unknown'; // Get the current user's email


    DatabaseReference currentUserRef = FirebaseDatabase.instance.ref().child("accounts").child(currentAdminUserId);
    DataSnapshot currentUserSnapshot = await currentUserRef.get();
    String currentAdminName = currentUserSnapshot.child("name").value as String;


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              maxWidth: 400, // Adjust the width of the dialog box
              maxHeight: 300, // Adjust the height of the dialog box
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  "New Admin Successfully Registered",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
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
                      onPressed: () async {

                        // Log the activity with current admin's details
                        ActivityLogger logger = ActivityLogger();
                        await logger.logActivity(currentAdminUserId, "Added New Admin", currentAdminName, currentAdminEmail, role);
                        Navigator.of(context).pop();
                        // Optionally, you can navigate back or clear the form
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (c) => Super_Admin_Panel()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void validatePassword(String value) {
    setState(() {
      hasMinLength = value.length >= 8 && value.length <= 20;
      hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      hasSpecialChar =
          value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_]'));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          "Admin Web Panel",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
          children: [
            // Shimmer effect on the background
            Shimmer.fromColors(
              baseColor: Colors.blue.shade100,
              highlightColor: Colors.blue.shade50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.purple.shade300],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Create an Admin's Account",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(height: 15),

                              TextFormField(
                                controller: nameTextEditingController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: "Name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18),
                                onChanged: (text) {
                                  setState(() {});
                                },
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: phoneTextEditingController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                decoration: InputDecoration(
                                  labelText: "Phone Number (09XXXXXXXXX)",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18),
                                onChanged: (text) {
                                  setState(() {});
                                },
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller:
                                emailUsernameTextEditingController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: "Email Username",
                                  suffixText: "@tric.go",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18),
                                onChanged: (text) {
                                  setState(() {});
                                },
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: passwordTextEditingController,
                                obscureText: obscurePassword,
                                onChanged: validatePassword,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        hasMinLength ? Icons.check : Icons.close,
                                        color: hasMinLength ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('8-20 characters'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        hasUpperCase ? Icons.check : Icons.close,
                                        color: hasUpperCase ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('At least one uppercase letter'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        hasSpecialChar ? Icons.check : Icons.close,
                                        color: hasSpecialChar ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('At least one special character ex. !@#%^&*(),.?":{}|<>_'),
                                    ],
                                  ),
                                ],
                              ),SizedBox(height: 20),
                              //    DropdownButtonFormField<String>(
                              //      value: selectedCoding,
                              //      items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday','Saturday']
                              //          .map((String coding) => DropdownMenuItem<String>(
                              //        value: coding,
                              //        child: Text(coding),
                              //     ))
                              //          .toList(),
                              //      onChanged: (String? newValue) {
                              //       setState(() {
                              //         selectedCoding = newValue;
                              //       });
                              //     },
                              //     decoration: InputDecoration(
                              //       labelText: "Day of Coding",
                              //        border: OutlineInputBorder(
                              //         borderRadius: BorderRadius.circular(10),
                              //       ),
                              //     ),
                              //    ),
                              SizedBox(height: 20),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                items: ['Admin']
                                    .map((String role) =>
                                    DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ))
                                    .toList(),
                                onChanged: null,
                                decoration: InputDecoration(
                                  labelText: "Role",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Select Access Level",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Column(
                                children: [
                                  RadioListTile<String>(
                                    title: Text(
                                      "All Access (Full control over the system)",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: "Super Admin",
                                    groupValue: selectedAccess,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedAccess = value;
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: Text(
                                      "Manage Admin, Sub Admin & TODA",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: "Access #1",
                                    groupValue: selectedAccess,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedAccess = value;
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: Text(
                                      "Manage Admins (Add Admin)",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: "Access #2",
                                    groupValue: selectedAccess,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedAccess = value;
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: Text(
                                      "Manage Sub Admins (Add Sub Admin)",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: "Access #3",
                                    groupValue: selectedAccess,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedAccess = value;
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: Text(
                                      "View and Search (View and search records only)",
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: "Access #4",
                                    groupValue: selectedAccess,
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedAccess = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: isFormValid
                                    ? checkIfNetworkIsAvailable
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: isFormValid
                                      ? Colors.lightBlue
                                      : Colors.grey,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 50,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 5,
                                  textStyle: TextStyle(fontSize: 18),
                                  minimumSize: Size(200, 50),
                                ),
                                child: Text(
                                  "Create Account",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]
      ),
    );
  }
}
