//Super Admin
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import '../dashboard/Admin Panel Permissions/Admin_Panel.dart';
import '../dashboard/Admin Panel Permissions/Super_Admin_Panel.dart';
import '../methods/common_methods.dart';
import '../widgets/loading_dialog.dart';

class Add_TODA extends StatefulWidget {
  const Add_TODA({Key? key}) : super(key: key);

  @override
  State<Add_TODA> createState() => _Add_TODAState();
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

ActivityLogger activityLogger = ActivityLogger(); // Initialize the ActivityLogger

class _Add_TODAState extends State<Add_TODA> {
  TextEditingController todaNameTextEditingController = TextEditingController();
  TextEditingController areaServiceTextEditingController = TextEditingController();
  TextEditingController todaAbbreviationTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  bool get isFormValid {
    return todaNameTextEditingController.text.trim().isNotEmpty &&
        areaServiceTextEditingController.text.trim().isNotEmpty &&
        todaAbbreviationTextEditingController.text.trim().isNotEmpty;
  }

  checkIfNetworkIsAvailable() {
    signUpFormValidation();
  }

  signUpFormValidation() {
    if (todaNameTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar(
        "Please enter the full TODA name.",
        context,
      );
    } else if (areaServiceTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar(
        "Please enter the area of service.",
        context,
      );
    } else if (todaAbbreviationTextEditingController.text.trim().isEmpty) {
      cMethods.displaySnackBar(
        "Please enter the TODA abbreviation.",
        context,
      );
    } else {
      registerNewUser();
    }
  }

  registerNewUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(
        messageText: "Registering new TODA...",
      ),
    );

    try {
      DatabaseReference todaRef = FirebaseDatabase.instance.reference().child("toda");

      Map todaDataMap = {
        "toda_name": todaNameTextEditingController.text.trim() + " Tricycle Operators and Drivers' Association",
        "area_service": areaServiceTextEditingController.text.trim(),
        "toda_abbreviation": todaAbbreviationTextEditingController.text.trim(),
      };

      await todaRef.push().set(todaDataMap);

      Navigator.pop(context); // Close the loading dialog

      // Show success dialog
      showSuccessDialog(context);
    } catch (error) {
      Navigator.pop(context); // Close the loading dialog
      cMethods.displaySnackBar(error.toString(), context);
    }
  }

  void showSuccessDialog(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white60.withOpacity(0.9),
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          content: Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 300,
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
                  "TODA Added Successfully",
                  style: TextStyle(
                    fontSize: 18,
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) =>Admin_Panel()),
                          (route) => false,
                    );

                    if (user != null) {
                      // Fetch role and name
                      final userRef = FirebaseDatabase.instance.ref().child("accounts").child(user.uid);
                      final DatabaseEvent event = await userRef.once();
                      final userData = event.snapshot.value as Map<dynamic, dynamic>?;

                      String role = 'Unknown';
                      String name = 'Unknown';

                      if (userData != null) {
                        role = userData['role']?.toString() ?? 'Unknown';
                        name = userData['name']?.toString() ?? 'Unknown';
                      }
                      await activityLogger.logActivity(
                        user.uid,
                        'Added a new TODA',
                        name,
                        user.email ?? 'Unknown',
                        role,
                      );
                    }
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade200, Colors.grey.shade400],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Create a TODA Record",
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: todaNameTextEditingController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "Full TODA Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              suffixText: " Tricycle Operators and Drivers' Association",
                            ),
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                            onChanged: (text) {
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: areaServiceTextEditingController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "Area of Service",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                            onChanged: (text) {
                              setState(() {});
                            },
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: todaAbbreviationTextEditingController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              labelText: "TODA Abbreviation",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            style: TextStyle(color: Colors.grey, fontSize: 18),
                            onChanged: (text) {
                              setState(() {
                                todaAbbreviationTextEditingController.text = text.toUpperCase();
                                todaAbbreviationTextEditingController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: todaAbbreviationTextEditingController.text.length),
                                );
                              });
                            },
                          ),
                          SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Note: The letters in this field are automatically converted to uppercase.",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isFormValid ? checkIfNetworkIsAvailable : null,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: isFormValid ? Colors.lightBlue : Colors.grey,
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
                            child: Text("Create TODA"),
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
      ),
    );
  }
}
